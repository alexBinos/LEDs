/*
 1. Keep track of the pixel we are writing to
 2. Increment the address after each row
 
 Modes of operation
 0. Debug;
   Override address and latches with switches and write in a debug test pattern
   to determine; the pixel order, bit order and LE/OE functions
 
 1. Solid colour
   Write a solid, hard coded colour to the display on all lines
 
 2. RGB fade
   Write RGB fade to all colours at a fixed fade rate
 
 - Verify this works at clock frequencies between 1kHz and 1MHz
 
*/

module led_display_driver #(
   parameter integer NUM_ROWS           = 32,            // Number of rows in the matrix
   parameter integer NUM_COLS           = 64,            // Number of columns in the matrix
   parameter integer WRITE_FREQ         = 1_000_000,     // Data clock frequency (1MHz)
   parameter integer FADE_TIME          = 10_000_000,    // 10ms; time between updating the fade value
   parameter integer SYS_CLK_FREQ       = 100_000_000)   // Board clock frequency (100MHz)
(
   input wire           clk_in,
   input wire           n_reset_in,
   
   // Debug
   input wire [3:0]     mode_in,
   input wire [23:0]    colour_in,
   
   // Display control
   output wire          latch_enable_out,
   output wire          output_enable_out,
   output wire [2:0]    addr_out,
   output wire [2:0]    rgb_top_out,
   output wire [2:0]    rgb_bot_out,
   output wire          bit_clk_out
);
   
   //---------------------------------------------------------
   //             Local Parameters and Types                --
   //---------------------------------------------------------
   
   localparam integer COL_W             = $clog2(NUM_COLS + 1);
   localparam integer SYS_CLK_PER       = 1_000_000_000 / SYS_CLK_FREQ;
   localparam integer FADE_CYCLES       = (FADE_TIME / SYS_CLK_PER);       // Clock cycles to count
   localparam integer FADE_CYCLES_W     = $clog2(FADE_CYCLES + 1);
   
   //---------------------------------------------------------
   //                Variables and Signals                  --
   //---------------------------------------------------------
   
   // PHY control
   reg                           phy_enable;
   wire                          phy_ready;
   reg [23:0]                    pixel_top_phy;
   reg [23:0]                    pixel_bot_phy;
   reg [(COL_W - 1):0]           pixel_counter;
   
   // Display control
   reg [3:0]                     addr;
   reg                           latch_enable;
   reg                           output_enable;
   
   // Colour fade
   reg [23:0]                    fade;
   reg [(FADE_CYCLES_W - 1):0]   fade_counter;
   reg                           fade_trig;
   reg [7:0]                     fade_red;
   reg [7:0]                     fade_green;
   reg [7:0]                     fade_blue;
   
   //---------------------------------------------------------
   //                      PHY Control                      --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in, negedge n_reset_in) begin
      if (!n_reset_in) begin
         pixel_top_phy   <= 24'h000000;
         pixel_bot_phy   <= 24'h000000;
         addr            <= 3'b000;
         pixel_counter   <= {COL_W{1'b0}};
         latch_enable    <= 1'b0;
      end
      else begin
         if (phy_ready) begin
            pixel_counter   <= pixel_counter + 1'b1;
            phy_enable      <= 1'b1;
            latch_enable    <= 1'b0;
            // Colour mode select
            if (mode_in == 4'h1) begin
               // Solid colour
               pixel_top_phy <= colour_in;
               pixel_bot_phy <= colour_in;
            end
            else if (mode_in == 4'h2) begin
               // RGB fade
               pixel_top_phy <= fade;
               pixel_bot_phy <= fade;
            end
            else begin
               // Invalid mode
               pixel_top_phy <= 24'h000000;
               pixel_bot_phy <= 24'h000000;
            end
         end
         else begin
            phy_enable <= 1'b0;
            if (pixel_counter >= NUM_COLS) begin
               pixel_counter   <= {COL_W{1'b0}};
               addr            <= addr + 1'b1;
               latch_enable    <= 1'b1;
            end
         end
      end
   end
   
   // Colour fade
   always_ff @(posedge clk_in, negedge n_reset_in) begin
      if (!n_reset_in) begin
         fade         <= 24'h000000;
         fade_red     <= 8'hFF;
         fade_green   <= 8'h00;
         fade_blue    <= 8'h00;
      end
      else begin
         if (fade_trig) begin
            if ((fade_red > 8'h00) && (fade_blue == 8'h00)) begin
               fade_red     <= fade_red - 1'b1;
               fade_green   <= fade_green + 1'b1;
            end
            else if ((fade_green > 8'h00) && (fade_red == 8'h00)) begin
               fade_green   <= fade_green - 1'b1;
               fade_blue    <= fade_blue + 1'b1;
            end
            else if ((fade_blue > 8'h00) && (fade_green == 8'h00)) begin
               fade_blue    <= fade_blue - 1'b1;
               fade_red     <= fade_red + 1'b1;
            end
            else begin
               // Something went wrong, reset to default state
               fade_red     <= 8'hFF;
               fade_green   <= 8'h00;
               fade_blue    <= 8'h00;
            end
         end
         else begin
            fade[23:0] <= {fade_red[7:0], fade_green[7:0], fade_blue[7:0]};
         end
      end
   end
   
   // Slow clock for colour fade
   always_ff @(posedge clk_in, negedge n_reset_in) begin
      if (!n_reset_in) begin
         fade_counter    <= {FADE_CYCLES_W{1'b0}};
         fade_trig       <= 1'b0;
      end
      else begin
         if (fade_counter >= FADE_CYCLES) begin
            fade_counter    <= {FADE_CYCLES_W{1'b0}};
            fade_trig       <= 1'b1;
         end
         else begin
            fade_counter    <= fade_counter + 1'b1;
            fade_trig       <= 1'b0;
         end
      end
   end
   
   //---------------------------------------------------------
   //                      Display PHY                      --
   //---------------------------------------------------------
   
   led_display_driver_phy #(
         .WRITE_FREQ    ( WRITE_FREQ ),
         .SYS_CLK_FREQ  ( SYS_CLK_FREQ ))
      led_display_phy_inst (
         .clk_in        ( clk_in ),
         .n_reset_in    ( n_reset_in ),
         .enable_in     ( phy_enable ),
         .ready_out     ( phy_ready ),
            
         .pixel_top_in  ( pixel_top_phy ),
         .pixel_bot_in  ( pixel_bot_phy ),
         
         .rgb_top_out   ( rgb_top_out ),
         .rgb_bot_out   ( rgb_bot_out ),
         .bit_clk_out   ( bit_clk_out ));
   
   //---------------------------------------------------------
   //                   Output Control                      --
   //---------------------------------------------------------
   
   assign addr_out             = addr;
   assign latch_enable_out     = latch_enable;
   assign output_enable        = 1'b1; // TODO: Better implementation for OE
   assign output_enable_out    = output_enable;
   
endmodule
