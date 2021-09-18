`timescale 1ns / 1ps

module display_sim (
   input wire        bclk,
   input wire [2:0]  rgb_top,
   input wire [2:0]  rgb_bot,
   input wire [2:0]  addr_in,
   input wire        oe_in,
   input wire        le_in
);
   
   logic  n_reset;
   
   logic [23:0] pxl_top;
   logic [23:0] pxl_bot;
   logic [3:0] addr;
   reg [7:0] r_top;
   reg [7:0] g_top;
   reg [7:0] b_top;
   reg [7:0] r_bot;
   reg [7:0] g_bot;
   reg [7:0] b_bot;
   
   bit [7:0] bit_cntr;
   bit bit_cntr_rst;
   bit [1:0] bclk_buf;
   
   always_ff @(posedge bclk) begin
      if (!n_reset) begin
         r_top <= 8'h00;
         g_top <= 8'h00;
         b_top <= 8'h00;
         r_bot <= 8'h00;
         g_bot <= 8'h00;
         b_bot <= 8'h00;
      end
      else begin
         r_top[7:0] <= {r_top[6:0], rgb_top[0]};
         g_top[7:0] <= {g_top[6:0], rgb_top[1]};
         b_top[7:0] <= {b_top[6:0], rgb_top[2]};
         r_bot[7:0] <= {r_bot[6:0], rgb_bot[0]};
         g_bot[7:0] <= {g_bot[6:0], rgb_bot[1]};
         b_bot[7:0] <= {b_bot[6:0], rgb_bot[2]};
         addr <= addr_in;
      end
   end
   
   assign pxl_top[23:0] = {b_top[7:0], g_top[7:0], r_top[7:0]};
   assign pxl_bot[23:0] = {b_bot[7:0], g_bot[7:0], r_bot[7:0]};
   
   bit clk;
   initial forever #1 clk = ~clk;
   
   always_ff @(posedge clk) begin
      bclk_buf[1:0] <= {bclk_buf[0], bclk};
      
      if (bclk_buf == 2'b01) begin
         bit_cntr <= bit_cntr + 1'b1;
      end
      else if (bit_cntr >= 8) begin
         bit_cntr <= 8'h00;
         $display("Pixel received: Addr: %h, Top: %h, Bottom: %h", addr, pxl_top, pxl_bot);
      end
   end
   
   int timeout_counter;
   initial begin
      forever begin
         #5
         timeout_counter++;
         if (timeout_counter > 1000) begin
            n_reset = 1'b0;
         end
         else if (bclk) begin
            timeout_counter = 0;
            n_reset = 1'b1;
         end
      end
   end
   
   initial begin
      forever begin
         @(posedge clk)
         if (bit_cntr >= 24) begin
            //$display("Pixel received: Top: %h, Bottom: %h", pxl_top, pxl_bot);
         end
      end
   end
   
endmodule
