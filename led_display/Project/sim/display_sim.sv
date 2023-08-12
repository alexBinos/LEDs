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
   
   logic [3:0] addr;
   
   rgb_row_t pxl;
   rgb_row_t frame[$];
   
   initial begin : shift_reg
      forever begin
         @(posedge bclk);
         #1step
         pxl.top.red     <= {pxl.top.red[(NUM_COLS - 2):0], rgb_top[0]};
         pxl.top.green   <= {pxl.top.green[(NUM_COLS - 2):0], rgb_top[1]};
         pxl.top.blue    <= {pxl.top.blue[(NUM_COLS - 2):0], rgb_top[2]};
         pxl.bot.red     <= {pxl.bot.red[(NUM_COLS - 2):0], rgb_bot[0]};
         pxl.bot.green   <= {pxl.bot.green[(NUM_COLS - 2):0], rgb_bot[1]};
         pxl.bot.blue    <= {pxl.bot.blue[(NUM_COLS - 2):0], rgb_bot[2]};
      end
   end : shift_reg
   
   always_ff @(posedge le_in) begin
      update_queue();
   end
   
   task update_queue();
      frame.push_back(pxl);
      if (VERBOSE) begin
         $display("Row received: Addr: %h, Top: %h, Bottom: %h at time %t", addr_in, pxl.top, pxl.bot, $time);
      end
   endtask : update_queue
   
   task reset();
      pxl = {GL_RGB_ROW_W{1'b0}};
   endtask : reset
   
endmodule
