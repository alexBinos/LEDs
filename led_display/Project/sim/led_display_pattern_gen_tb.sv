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
   
   parameter integer VERBOSE = 0;
   
   //---------------------------------------------------------
   //                         Signals                       --
   //---------------------------------------------------------
   
   logic [2:0] ptg_colour;
   logic [3:0] ptg_mode;
   rgb_row_t   ptg_row;
   logic       ptg_row_valid;
   logic       ptg_row_ready;
   logic [3:0] ptg_row_address;
   
   int num_tests;
   
   rgb_row_t row[$];
   logic [3:0] address[$];
   
   int address_error_count;
   int data_error_count;
   
   //---------------------------------------------------------
   //                   UUT - Display Driver PHY            --
   //---------------------------------------------------------
   
   led_display_pattern_gen #(
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ),
         .SIMULATION          ( 1 ))
      dut (
         .clk_in              ( clk_in ),
         .n_reset_in          ( n_reset_in ),
         .colour_in           ( ptg_colour ),
         .mode_in             ( ptg_mode ),
         .row_out             ( ptg_row ),
         .row_valid_out       ( ptg_row_valid ),
         .row_ready_in        ( ptg_row_ready ),
         .row_address_out     ( ptg_row_address ));
   
   //---------------------------------------------------------
   //                         Tests                         --
   //---------------------------------------------------------
   
   task test_00 (output bit pass);
      bit pass_local;
      pass = 1'b1;
      
      $display("LED display pattern generator Test 00: Basic patterns");
      
      drive(dut.MODE_OFF, 0);
      check_datastream(pass_local);
      pass &= pass_local;
      # 1000;
      
      for (int i = 0; i < 8; i++) begin
         drive(dut.MODE_SOLID, i[2:0]);
         check_datastream(pass_local);
         pass &= pass_local;
      end
      
      if (pass) begin
         $display("Pass");
      end
      else begin
         $display("Fail");
      end
      
      return;
   endtask : test_00
   
   task test_01 (output bit pass);
      $display("LED display pattern generator Test 01: Scan pattern");
      
      pass = 1;
      
      // TODO: vscan
      drive(dut.MODE_SCAN_V, 1);
      # 1000000;
      
      if (pass) begin
         $display("Pass");
      end
      else begin
         $display("Fail");
      end
      
      return;
   endtask : test_01
   
   task test_02 (output bit pass);
      $display("LED display pattern generator Test 02: PWM effects");
      
      pass = 1;
      
      drive(dut.MODE_PULSE, 2);
      # 10_000_000;
      
      if (pass) begin
         $display("Pass");
      end
      else begin
         $display("Fail");
      end
      
      return;
   endtask : test_02
   
   //---------------------------------------------------------
   //                   Simulation Tasks                    --
   //---------------------------------------------------------
   
   task automatic sim_init();
      num_tests = 10;
      ptg_row_ready = 1'b0;
      ptg_mode = {4{1'b0}};
      ptg_colour = {3{1'b0}};
      row.delete();
      address.delete();
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
      address_error_count = 0;
      data_error_count = 0;
   endtask : reset_error_counters
   
   //---------------------------------------------------------
   //                         Driver                        --
   //---------------------------------------------------------
   
   task automatic drive(input logic [3:0] mode, input logic [2:0] col);
      
      sim_cycles(1);
      ptg_row_ready = 1'b1;
      ptg_mode = mode[3:0];
      ptg_colour = col[2:0];
      
      for (int i = 0; i < num_tests; i++) begin
         sim_cycles(1);
      end
      
      ptg_row_ready = 1'b0;
      sim_cycles(1);
      
      return;
   endtask : drive
   
   //---------------------------------------------------------
   //                      Monitors                         --
   //---------------------------------------------------------
   
   task static monitor_address();
      int expected = 0;
      int mode = 0;
      
      sim_cycles(1);
      
      if (ptg_mode != mode) begin
         mode = ptg_mode;
         expected = 0;
         if (VERBOSE) $display("New expected mode: %d", mode);
      end
      
      if (!(ptg_row_address == expected)) begin
         address_error_count++;
         $display("Address error; Expected: %d, Read %d; Time: %t", expected, ptg_row_address, $time);
      end
      
      if (ptg_row_valid) begin
         expected++;
         if (expected == 16) begin
            expected = 0;
         end
         if (VERBOSE) $display("New expected address: %d", expected);
      end
      
      return;
   endtask : monitor_address
   
   task static monitor_datastream();
      
      sim_cycles(1);
      if (ptg_row_valid) begin
         row.push_back(ptg_row);
         address.push_back(ptg_row_address);
      end
      
      return;
   endtask : monitor_datastream
   
   initial begin
      forever begin
         monitor_datastream();
      end
   end
   
   task automatic check_datastream(output bit pass);
      rgb_row_t expected;
      bit pass_local;
      int t = row.size();
      pass = 1'b1;
      
      
      case (ptg_mode)
         dut.MODE_OFF : begin
            $display("Checking mode off %t", $time);
            expected = {GL_RGB_ROW_W{1'b0}};
         end
         
         dut.MODE_SOLID : begin
            $display("Checking mode solid colour %X %t", ptg_colour, $time);
            expected.top.red     = {GL_NUM_COL_PIXELS{ptg_colour[0]}};
            expected.bot.red     = {GL_NUM_COL_PIXELS{ptg_colour[0]}};
            expected.top.green   = {GL_NUM_COL_PIXELS{ptg_colour[1]}};
            expected.bot.green   = {GL_NUM_COL_PIXELS{ptg_colour[1]}};
            expected.top.blue    = {GL_NUM_COL_PIXELS{ptg_colour[2]}};
            expected.bot.blue    = {GL_NUM_COL_PIXELS{ptg_colour[2]}};
         end
      endcase
      
      for (int i = 0; i < t; i++) begin
         pass_local = (expected == row.pop_front());
         pass &= pass_local;
      end
      
   endtask : check_datastream
   
endmodule
