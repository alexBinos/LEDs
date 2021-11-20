/*
               Display driver for LED matrix display
 
 State machine logic
 
 0. Wait for a new row of pixels
 1. Buffer row
 2. Shift out a new pixel after the rising edge of bit clock
 3a. Increment total bit count
 3b. If total bit count exceeds number of row bits, reset and increment address
 3c. Assert done signal to trigger memory controller to send another pixel
 3d. Return to IDLE
 
*/

module led_display_driver_phy #(
   parameter integer WRITE_FREQ         = 1_000_000,     // Data clock frequency (1MHz)
   parameter integer SYS_CLK_FREQ       = 100_000_000,   // Board clock frequency (100MHz)
   parameter integer NUM_COLS           = 64)            // Number of columns in the matrix
(
   // Module control
   input wire           clk_in,
   input wire           n_reset_in,
   input wire           enable_in,
   output wire          ready_out,
   
   // Pixels to write
   input wire [2:0][(NUM_COLS - 1):0]    col_bot_in,
   input wire [2:0][(NUM_COLS - 1):0]    col_top_in,
   
   // Display control
   output wire [2:0]    rgb_top_out,
   output wire [2:0]    rgb_bot_out,
   output wire          bit_clk_out
);
   
   //---------------------------------------------------------
   //             Local Parameters and Types                --
   //---------------------------------------------------------
   
   genvar i;
   
   localparam integer BIT_CLK_COUNT = SYS_CLK_FREQ / (WRITE_FREQ * 2); // Half period count
   localparam integer BIT_CLK_COUNT_W = $clog2(BIT_CLK_COUNT + 1);
   localparam integer NUM_COLS_W = $clog2(NUM_COLS + 1);
   
   typedef enum logic [3:0]{
      SS_IDLE,
      SS_WRITE,
      SS_DONE
   } state_t;
   
   state_t state;
   
   //---------------------------------------------------------
   //                Variables and Signals                  --
   //---------------------------------------------------------
   
   // Bit clock
   reg [(BIT_CLK_COUNT_W - 1):0]    bclk_cntr;
   reg                              bclk;
   reg                              bclk_nsclr;
   reg [1:0]                        bclk_buf;
   reg                              s_ready;
   
   reg [(NUM_COLS_W - 1):0]         pixel_bit_counter;
   
   reg [2:0][(NUM_COLS - 1):0] col_top_buf;
   reg [2:0][(NUM_COLS - 1):0] col_bot_buf;
   
   //---------------------------------------------------------
   //                   Main State Machine                  --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in, negedge n_reset_in) begin
      if (!n_reset_in) begin
         state <= SS_IDLE;
         bclk_nsclr <= 1'b1;
         pixel_bit_counter <= {NUM_COLS_W{1'b0}};
         s_ready <= 1'b1;
      end
      else begin
         case (state)
            SS_IDLE : begin
               if (enable_in) begin
                  s_ready <= 1'b0;
                  state <= SS_WRITE;
               end
               else begin
                  s_ready <= 1'b1;
                  bclk_nsclr <= 1'b0;
               end
            end
            
            SS_WRITE : begin
               bclk_nsclr <= 1'b1;
               if (pixel_bit_counter >= NUM_COLS) begin
                  state <= SS_DONE;
               end
               else if (bclk_buf == 2'b10) begin
                  // Shift data on falling edge
                  pixel_bit_counter <= pixel_bit_counter + 1'b1;
               end
            end
            
            SS_DONE : begin
               s_ready <= 1'b1;
               bclk_nsclr <= 1'b0;
               pixel_bit_counter <= {NUM_COLS_W{1'b0}};
               state <= SS_IDLE;
            end
         endcase
      end
   end
   
   generate
      for (i = 0; i < NUM_COLS; i++) begin : g_pixel_logic
         always_ff @(posedge clk_in, negedge n_reset_in) begin
            if (!n_reset_in) begin
               col_top_buf[i] <= {NUM_COLS{1'b0}};
               col_bot_buf[i] <= {NUM_COLS{1'b0}};
            end
            else begin
               if (state == SS_IDLE) begin
                  if (enable_in) begin
                     col_top_buf[i] <= col_top_in[i];
                     col_bot_buf[i] <= col_bot_in[i];
                  end
                  else begin
                     col_top_buf[i] <= {NUM_COLS{1'b0}};
                     col_bot_buf[i] <= {NUM_COLS{1'b0}};
                  end
               end
               else if (state == SS_WRITE) begin
                  if (bclk_buf == 2'b10) begin
                     col_top_buf[i][(NUM_COLS - 1):0] <= {col_top_buf[i][(NUM_COLS - 2):0], 1'b0};
                     col_bot_buf[i][(NUM_COLS - 1):0] <= {col_bot_buf[i][(NUM_COLS - 2):0], 1'b0};
                  end
               end
               else if (state == SS_DONE) begin
                  col_top_buf[i] <= {NUM_COLS{1'b0}};
                  col_bot_buf[i] <= {NUM_COLS{1'b0}};
               end
            end
         end
      end
   endgenerate
   
   //---------------------------------------------------------
   //                   Clock Generation                    --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in, negedge n_reset_in) begin
      if (!n_reset_in) begin
         bclk_cntr <= {BIT_CLK_COUNT_W{1'b0}};
         bclk <= 1'b0;
         bclk_buf <= 2'b00;
      end
      else begin
         bclk_buf[1:0] <= {bclk_buf[0], bclk};
         
         if (!bclk_nsclr) begin
            bclk_cntr <= {BIT_CLK_COUNT_W{1'b0}};
            bclk <= 1'b0;
         end
         else if (bclk_cntr >= BIT_CLK_COUNT) begin
            bclk_cntr <= {BIT_CLK_COUNT_W{1'b0}};
            bclk <= ~bclk;
         end
         else begin
            bclk_cntr <= bclk_cntr + 1'b1;
         end
      end
   end
   
   //---------------------------------------------------------
   //                   Output Control                      --
   //---------------------------------------------------------
   
   generate
      for (i = 0; i < NUM_COLS; i++) begin : g_output_logic
         assign rgb_top_out[i] = col_top_buf[i][(NUM_COLS - 1)];
         assign rgb_bot_out[i] = col_bot_buf[i][(NUM_COLS - 1)];
      end
   endgenerate
   
   assign bit_clk_out = bclk;
   assign ready_out = s_ready;
   
endmodule
