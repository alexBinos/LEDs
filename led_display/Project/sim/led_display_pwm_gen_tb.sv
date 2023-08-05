`timescale 1ns / 1ps

module led_display_pwm_gen_tb #(
   parameter integer SYS_CLK_FREQ       = 100_000_000,
   parameter integer PWM_FREQ           = 20_480,
   parameter integer BIT_W              = 8
)(
   input  wire clk_in,
   input  wire n_reset_in
);
   
   import led_display_package::*;
   
   parameter integer VERBOSE = 0;
   
   //---------------------------------------------------------
   //                         Signals                       --
   //---------------------------------------------------------
   
   logic [(BIT_W - 1):0]   pwm_val;
   logic                   pwm_serial;
   
   int num_tests;
   
   //---------------------------------------------------------
   //                   UUT - Display Driver PHY            --
   //---------------------------------------------------------
   
   pwm_generator #(
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ),
         .SIMULATION          ( 1 ))
      dut (
         .clk_in              ( clk_in ),
         .n_reset_in          ( n_reset_in ),
         .colour_in           ( pwm_val ),
         .pwm_colour_out      ( pwm_serial ));
   
   //---------------------------------------------------------
   //                         Tests                         --
   //---------------------------------------------------------
   
   task test_00 (output bit pass);
      $display("PWM generator Test 00: Single width");
      
      pass = 1;
      
      
      if (pass) begin
         $display("Pass");
      end
      else begin
         $display("Fail");
      end
      
      return;
   endtask
   
   task test_01 (output bit pass);
      $display("LED display pattern generator Test 01: Sweep");
      
      pass = 1;
      
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
      pwm_val = {BIT_W{1'b0}};
      reset_error_counters();
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
   
   task reset_error_counters();
      
      return;
   endtask : reset_error_counters
   
   //---------------------------------------------------------
   //                         Driver                        --
   //---------------------------------------------------------
   
   task automatic drive(input logic [3:0] mode);
      
      sim_cycles(1);
      
      return;
   endtask : drive
   
   //---------------------------------------------------------
   //                      Monitors                         --
   //---------------------------------------------------------
   
   
endmodule
