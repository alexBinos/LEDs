`timescale 1ns / 1ps

module display_sim #(
   parameter integer NUM_COLS = 64,
   parameter integer NUM_ROWS = 32,
   parameter integer VERBOSE = 1)
(
   input wire        bclk,
   input wire [2:0]  rgb_top,
   input wire [2:0]  rgb_bot,
   input wire [3:0]  addr_in,
   input wire        oe_in,
   input wire        le_in
);
   
   import led_display_package::*;
      
   genvar i;
   
   logic  n_reset;
   
   pxl_col_t pxl_top;
   pxl_col_t pxl_bot;
   logic [3:0] addr;
   
   int bit_counter;
   
   bit [7:0] bit_cntr;
   bit bit_cntr_rst;
   bit [1:0] bclk_buf;
   
   pxl_col_t frame_top[$];
   pxl_col_t frame_bot[$];
   
   initial begin : shift_reg
      forever begin
         @(posedge bclk);
         pxl_top.red     <= {pxl_top.red[(NUM_COLS - 2):0], rgb_top[2]};
         pxl_top.green   <= {pxl_top.green[(NUM_COLS - 2):0], rgb_top[1]};
         pxl_top.blue    <= {pxl_top.blue[(NUM_COLS - 2):0], rgb_top[0]};
         pxl_bot.red     <= {pxl_bot.red[(NUM_COLS - 2):0], rgb_bot[2]};
         pxl_bot.green   <= {pxl_bot.green[(NUM_COLS - 2):0], rgb_bot[1]};
         pxl_bot.blue    <= {pxl_bot.blue[(NUM_COLS - 2):0], rgb_bot[0]};
         #1step
         bit_counter++;
         
         if (bit_counter == NUM_COLS) begin
            update_queue();
            bit_counter = 0;
         end
      end
   end : shift_reg
   
   task update_queue();
      $display("Writing %X at time %t", pxl_top, $time);
      frame_top.push_back(pxl_top);
      frame_bot.push_back(pxl_bot);
      if (VERBOSE) begin
         $display("Row received: Addr: %h, Top: %h, Bottom: %h", addr, pxl_top, pxl_bot);
      end
   endtask : update_queue
   
   task reset();
      pxl_top = 'b0;
      pxl_bot = 'b0;
      bit_counter = 0;
   endtask : reset
   
endmodule
