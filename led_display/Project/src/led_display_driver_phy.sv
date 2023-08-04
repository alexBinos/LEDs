/*                Display driver for LED matrix display
 
 This module will buffer the incomming datastream and shift data out MSB first.
 The bit clock is gated and driven from the main module clock, the latch signal
 asserts for one clock cycle after a row is written.
 
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
   output wire          latch_out,
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
   reg                                 write_row;
   reg                                 latch;
   
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
         else if (pixel_bit_counter == 1'b0) begin
            row_ready <= 1'b1;
         end
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         pixel_bit_counter <= (GL_NUM_COL_PIXELS - 1);
      end
      else begin
         if (row_valid_in) begin
            pixel_bit_counter <= (GL_NUM_COL_PIXELS - 1);
         end
         else if (pixel_bit_counter > 0) begin
            pixel_bit_counter <= pixel_bit_counter - 1'b1;
         end
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         write_row <= 1'b0;
      end
      else begin
         if (row_valid_in) begin
            write_row <= 1'b1;
         end
         else if (pixel_bit_counter == 0) begin
            write_row <= 1'b0;
         end
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         latch <= 1'b0;
      end
      else begin
         if ((pixel_bit_counter == 0) && write_row) begin
            latch <= 1'b1;
         end
         else begin
            latch <= 1'b0;
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
   assign bit_clk_out    = write_row ? clk_in : 1'b0;
   assign row_ready_out  = row_ready;
   assign latch_out      = latch;
   
endmodule
