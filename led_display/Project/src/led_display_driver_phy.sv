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

import led_display_package::*;

module led_display_driver_phy #(
   parameter integer SYS_CLK_FREQ       = 100_000_000   // Board clock frequency (100MHz)
)(
   // Module control
   input wire           clk_in,
   input wire           n_reset_in,
   
   // Pixel streaming interface
   input  wire          row_valid_in,
   input  pxl_col_t     row_top_in,
   input  pxl_col_t     row_bot_in,
   output wire          row_ready_out,
   
   // Display control
   output wire          red_top_out,
   output wire          green_top_out,
   output wire          blue_top_out,
   output wire          red_bot_out,
   output wire          green_bot_out,
   output wire          blue_bot_out,
   output wire          bit_clk_out
);
   
   //---------------------------------------------------------
   //             Local Parameters and Types                --
   //---------------------------------------------------------
   
   genvar i;
   
   //---------------------------------------------------------
   //                Variables and Signals                  --
   //---------------------------------------------------------
   
   reg [(GL_NUM_COL_PIXELS_W - 1):0]   pixel_bit_counter;
   pxl_col_t                           row_top_buf;
   pxl_col_t                           row_bot_buf;
   reg                                 row_ready;
   
   //---------------------------------------------------------
   //                   Main State Machine                  --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         row_top_buf <= {GL_RGB_COL_W{1'b0}};
         row_bot_buf <= {GL_RGB_COL_W{1'b0}};
         row_ready <= 1'b1;
      end
      else begin
         if (row_valid_in) begin
            row_ready <= 1'b0;
            row_top_buf <= row_top_in;
            row_bot_buf <= row_bot_in;
         end
         else if (pixel_bit_counter <= 1'b1) begin
            row_ready <= 1'b1;
         end
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         pixel_bit_counter <= GL_NUM_COL_PIXELS;
      end
      else begin
         if (row_valid_in) begin
            pixel_bit_counter <= GL_NUM_COL_PIXELS;
         end
         else if (pixel_bit_counter > 0) begin
            pixel_bit_counter <= pixel_bit_counter - 1'b1;
         end
      end
   end
   
   //---------------------------------------------------------
   //                   Output Control                      --
   //---------------------------------------------------------
   
   assign red_top_out    = row_top_buf.red[pixel_bit_counter];
   assign green_top_out  = row_top_buf.green[pixel_bit_counter];
   assign blue_top_out   = row_top_buf.blue[pixel_bit_counter];
   assign red_bot_out    = row_bot_buf.red[pixel_bit_counter];
   assign green_bot_out  = row_bot_buf.green[pixel_bit_counter];
   assign blue_bot_out   = row_bot_buf.blue[pixel_bit_counter];
   assign bit_clk_out    = clk_in;
   assign row_ready_out  = row_ready;
   
endmodule
