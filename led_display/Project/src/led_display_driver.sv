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
   
      localparam integer COL_W = $clog2(NUM_COLS + 1);
   
   //---------------------------------------------------------
   //                Variables and Signals                  --
   //---------------------------------------------------------
   
   reg phy_enable;
   wire phy_ready;
   reg [23:0] pixel_top_phy;
   reg [23:0] pixel_bot_phy;
   
   reg [(COL_W - 1):0] pixel_counter;
   reg [3:0] addr;
   
   
   //---------------------------------------------------------
   //                      PHY Control                      --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in, negedge n_reset_in) begin
      if (!n_reset_in) begin
         pixel_top_phy <= 24'h000000;
         pixel_bot_phy <= 24'h000000;
         addr <= 3'b000;
         pixel_counter <= {COL_W{1'b0}};
      end
      else begin
         if (phy_ready) begin
            if (mode_in == 4'h1) begin
               // Solid colour
               pixel_top_phy <= colour_in;
               pixel_bot_phy <= colour_in;
               pixel_counter <= pixel_counter + 1'b1;
               phy_enable <= 1'b1;
            end
         end
         else begin
            phy_enable <= 1'b0;
            if (pixel_counter >= NUM_COLS) begin
               pixel_counter <= {COL_W{1'b0}};
               addr <= addr + 1'b1;
            end
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
   
   assign addr_out = addr;
   
endmodule
