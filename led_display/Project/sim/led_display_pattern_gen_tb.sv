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
   
   int num_tests;
   
   //---------------------------------------------------------
   //                   UUT - Display Driver PHY            --
   //---------------------------------------------------------
   
   led_display_pattern_gen #(
         .WRITE_FREQ          ( BCLK_FREQ ),
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ),
         .NUM_COLS            ( NUM_COL_PIXELS ))
      led_display_driver_phy_uut (
         .clk_in              ( clk_in ),
         .n_reset_in          ( n_reset_in ));
   
   //---------------------------------------------------------
   //                         Tests                         --
   //---------------------------------------------------------
   
   task test_00 (output bit pass);
      $display("LED display pattern generator Test 00: Basic patterns");
      
      pass = 0;
      
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
   endtask : sim_init
   
   task automatic set_num_test(input int n);
      num_tests = n;
   endtask : set_num_test
   
endmodule
