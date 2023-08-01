`timescale 1ns / 1ps

module display_sim #(
   parameter integer NUM_COLS = 64,
   parameter integer NUM_ROWS = 32)
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
   
   bit [7:0] bit_cntr;
   bit bit_cntr_rst;
   bit [1:0] bclk_buf;
   
   pxl_col_t frame_top[$];
   pxl_col_t frame_bot[$];
   
   always_ff @(posedge bclk, negedge n_reset) begin
      if (!n_reset) begin
         pxl_top.red[(NUM_COLS - 1):0]     <= {NUM_COLS{1'b0}};
         pxl_top.green[(NUM_COLS - 1):0]   <= {NUM_COLS{1'b0}};
         pxl_top.blue[(NUM_COLS - 1):0]    <= {NUM_COLS{1'b0}};
         pxl_bot.red[(NUM_COLS - 1):0]     <= {NUM_COLS{1'b0}};
         pxl_bot.green[(NUM_COLS - 1):0]   <= {NUM_COLS{1'b0}};
         pxl_bot.blue[(NUM_COLS - 1):0]    <= {NUM_COLS{1'b0}};
      end
      else begin
         pxl_top.red[(NUM_COLS - 1):0]     <= {pxl_top.red[(NUM_COLS - 2):0], rgb_top[0]};
         pxl_top.green[(NUM_COLS - 1):0]   <= {pxl_top.green[(NUM_COLS - 2):0], rgb_top[1]};
         pxl_top.blue[(NUM_COLS - 1):0]    <= {pxl_top.blue[(NUM_COLS - 2):0], rgb_top[2]};
         pxl_bot.red[(NUM_COLS - 1):0]     <= {pxl_bot.red[(NUM_COLS - 2):0], rgb_bot[0]};
         pxl_bot.green[(NUM_COLS - 1):0]   <= {pxl_bot.green[(NUM_COLS - 2):0], rgb_bot[1]};
         pxl_bot.blue[(NUM_COLS - 1):0]    <= {pxl_bot.blue[(NUM_COLS - 2):0], rgb_bot[2]};
      end
   end
   
   always_ff @(posedge bclk, negedge n_reset) begin
      if (!n_reset) begin
         addr <= 4'h0;
      end
      else begin
         addr <= addr_in;
      end
   end
   
   bit clk;
   initial forever #1 clk = ~clk;
   
   always_ff @(posedge clk) begin
      bclk_buf[1:0] <= {bclk_buf[0], bclk};
      
      if (!n_reset) begin
         bit_cntr <= 8'h00;
      end
      if (bclk_buf == 2'b01) begin
         bit_cntr <= bit_cntr + 1'b1;
      end
      else if (bit_cntr >= NUM_COLS) begin
         bit_cntr <= 8'h00;
         frame_top.push_back(pxl_top);
         frame_bot.push_back(pxl_bot);
         $display("Row received: Addr: %h, Top: %h, Bottom: %h", addr, pxl_top, pxl_bot);
      end
   end
   
   task reset();
      n_reset = 1'b0;
      # 100
      n_reset = 1'b1;
   endtask : reset
   
endmodule
