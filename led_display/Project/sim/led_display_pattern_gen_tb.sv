`timescale 1ns / 1ps

module led_display_pattern_gen_tb #(
   parameter integer SYS_CLK_FREQ       = 100_000_000,
   parameter integer NUM_ROW_PIXELS     = 32,
   parameter integer NUM_COL_PIXELS     = 64,
   parameter integer BCLK_FREQ          = 21_000_000
)(
   input  wire clk_in,
   input  wire n_reset_in
);
   
   import led_display_package::*;
   
   //---------------------------------------------------------
   //                         Signals                       --
   //---------------------------------------------------------
   
   logic [3:0] ptg_mode;
   rgb_row_t   ptg_row;
   logic       ptg_row_valid;
   logic       ptg_row_ready;
   logic [3:0] ptg_row_address;
   
   int num_tests;
   
   //---------------------------------------------------------
   //                   UUT - Display Driver PHY            --
   //---------------------------------------------------------
   
   led_display_pattern_gen #(
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ))
      led_display_driver_phy_uut (
         .clk_in              ( clk_in ),
         .n_reset_in          ( n_reset_in ),
         .mode_in             ( ptg_mode ),
         .row_out             ( ptg_row ),
         .row_valid_out       ( ptg_row_valid ),
         .row_ready_in        ( ptg_row_ready ),
         .row_address_out     ( ptg_row_address ));
   
   //---------------------------------------------------------
   //                         Tests                         --
   //---------------------------------------------------------
   
   task test_00 (output bit pass);
      $display("LED display pattern generator Test 00: Basic patterns");
      
      pass = 0;
      
      for (int m = 0; m < 7; m++) begin
         drive(m);
         
         # 1000;
      end
      
      if (pass) begin
         $display("Pass");
      end
      else begin
         $display("Fail");
      end
      
      return;
   endtask
   
   //---------------------------------------------------------
   //                   Simulation Tasks                    --
   //---------------------------------------------------------
   
   task automatic sim_init();
      num_tests = 10;
      ptg_row_ready = 1'b1;
      ptg_mode = {4{1'b0}};
   endtask : sim_init
   
   task automatic set_num_test(input int n);
      num_tests = n;
   endtask : set_num_test
   
   task automatic sim_cycles(int n);
      repeat (n) begin
         @(posedge clk_in);
      end
      #1step;
      return;
   endtask : sim_cycles
   
   task automatic drive(input logic [3:0] mode);
      
      sim_cycles(1);
      ptg_row_ready = 1'b1;
      ptg_mode = mode[3:0];
      
      sim_cycles(2);
      for (int i = 0; i < num_tests; i++) begin
         // TODO: Random ready toggling
         ptg_row_ready = ~ptg_row_ready;
         sim_cycles(1);
      end
      
      return;
   endtask : drive
   
   task static monitor_address();
      int expected = 0;
      int mode = 0;
      int error_count = 0;
      
      sim_cycles(1);
      
      if (ptg_mode != mode) begin
         mode = ptg_mode;
         expected = 0;
         // $display("New expected mode: %d", mode);
      end
      
      if (ptg_row_address != expected) begin
         error_count++;
         $display("Address error; Expected: %d, Read %d; Time: %t", expected, ptg_row_address, $time);
      end
      
      if (ptg_row_valid) begin
         expected++;
         if (expected == 16) begin
            expected = 0;
         end
         // $display("New expected address: %d", expected);
      end
      
      return;
   endtask : monitor_address
   
   initial begin
      forever begin
         monitor_address();
      end
   end
   
endmodule
