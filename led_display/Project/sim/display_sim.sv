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
   
   genvar i;
   
   logic  n_reset;
   
   logic [2:0][(NUM_COLS - 1):0] pxl_top;
   logic [2:0][(NUM_COLS - 1):0] pxl_bot;
   logic [3:0] addr;
   
   bit [7:0] bit_cntr;
   bit bit_cntr_rst;
   bit [1:0] bclk_buf;
   
   generate
      for (i = 0; i < NUM_COLS; i++) begin : g_row_logic
         always_ff @(posedge bclk, negedge n_reset) begin
            if (!n_reset) begin
               pxl_top[i] <= {NUM_COLS{1'b0}};
               pxl_bot[i] <= {NUM_COLS{1'b0}};
            end
            else begin
               pxl_top[i][(NUM_COLS - 1):0] <= {pxl_top[i][(NUM_COLS - 2):0], rgb_top[i]};
               pxl_bot[i][(NUM_COLS - 1):0] <= {pxl_bot[i][(NUM_COLS - 2):0], rgb_bot[i]};
            end
         end
      end
   endgenerate
   
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
         $display("Row received: Addr: %h, Top: %h, Bottom: %h", addr, pxl_top, pxl_bot);
      end
   end
   
   int timeout_counter = 0;
   initial begin
      forever begin
         #5
         if (timeout_counter < 10) begin
            timeout_counter++;
            n_reset = 1'b0;
         end
         else begin
            n_reset = 1'b1;
         end
      end
   end
   
endmodule
