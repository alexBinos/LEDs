`timescale 1ns / 1ps

module led_display_driver_tb #(
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
   
   logic [2:0] drv_bit_top;
   logic [2:0] drv_bit_bot;
   logic       drv_bclk;
   logic       drv_latch;
   
   int num_tests;
   
   int address_error_count;
   int data_error_count;
   
   //---------------------------------------------------------
   //                   DUT - Display Driver                --
   //---------------------------------------------------------
   
   led_display_pattern_gen #(
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ),
         .SIMULATION          ( 1 ))
      dut_ptg (
         .clk_in              ( clk_in ),
         .n_reset_in          ( n_reset_in ),
         .colour_in           ( ptg_colour ),
         .mode_in             ( ptg_mode ),
         .row_out             ( ptg_row ),
         .row_valid_out       ( ptg_row_valid ),
         .row_ready_in        ( ptg_row_ready ),
         .row_address_out     ( ptg_row_address ));
   
   led_display_driver_phy #(
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ))
      dut_drv (
         .clk_in              ( clk_in ),
         .n_reset_in          ( n_reset_in ),
         
         .row_in              ( ptg_row ),
         .row_valid_in        ( ptg_row_valid ),
         .row_ready_out       ( ptg_row_ready ),
         
         .latch_out           ( drv_latch ),
         .red_top_out         ( drv_bit_top[0] ),
         .green_top_out       ( drv_bit_top[1] ),
         .blue_top_out        ( drv_bit_top[2] ),
         .red_bot_out         ( drv_bit_bot[0] ),
         .green_bot_out       ( drv_bit_bot[1] ),
         .blue_bot_out        ( drv_bit_bot[2] ),
         .bit_clk_out         ( drv_bclk ));
   
   //---------------------------------------------------------
   //                   Sim - Display Module                --
   //---------------------------------------------------------
   
   display_sim #(
         .NUM_COLS   ( NUM_COL_PIXELS ),
         .NUM_ROWS   ( NUM_ROW_PIXELS ),
         .VERBOSE    ( VERBOSE ))
      display_sim_inst (
         .bclk       ( drv_bclk ),
         .rgb_top    ( drv_bit_top ),
         .rgb_bot    ( drv_bit_bot ),
         .addr_in    ( ptg_row_address ),
         .oe_in      ( !drv_latch ),
         .le_in      ( drv_latch ));
   
   //---------------------------------------------------------
   //                         Tests                         --
   //---------------------------------------------------------
   
   task test_00 (output bit pass);
      $display("LED display pattern generator Test 00: Basic patterns");
      
      pass = 1;
      
      drive(dut_ptg.MODE_OFF, 0);
      # 1000;
      
      drive(dut_ptg.DEBUG_V, 1);
      
      # 10_000
      
      if (pass) begin
         $display("Pass");
      end
      else begin
         $display("Fail");
      end
      
      return;
   endtask : test_00
   
   //---------------------------------------------------------
   //                   Simulation Tasks                    --
   //---------------------------------------------------------
   
   task automatic sim_init();
      num_tests = 10;
      ptg_mode = {4{1'b0}};
      ptg_colour = {3{1'b0}};
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
      ptg_mode = mode[3:0];
      ptg_colour = col[2:0];
      
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
   
   initial begin
      forever begin
         monitor_address();
      end
   end
   
   task static monitor_valid();
      bit expected = 0;
      // TODO
      sim_cycles(1);
      
      
   endtask : monitor_valid
   
   task static monitor_datastream();
      rgb_row_t expected;
      
      expected = {GL_RGB_ROW_W{1'b0}};
      sim_cycles(1);
      case (ptg_mode)
         dut_ptg.MODE_OFF : begin
            expected = {GL_RGB_ROW_W{1'b0}};
         end
         
         dut_ptg.MODE_SOLID : begin
            expected.top.red     <= {GL_NUM_COL_PIXELS{ptg_colour[0]}};
            expected.bot.red     <= {GL_NUM_COL_PIXELS{ptg_colour[0]}};
            expected.top.green   <= {GL_NUM_COL_PIXELS{ptg_colour[1]}};
            expected.bot.green   <= {GL_NUM_COL_PIXELS{ptg_colour[1]}};
            expected.top.blue    <= {GL_NUM_COL_PIXELS{ptg_colour[2]}};
            expected.bot.blue    <= {GL_NUM_COL_PIXELS{ptg_colour[2]}};
         end
      endcase
      
      if (ptg_row_valid) begin
         if (!(expected == ptg_row)) begin
            data_error_count++;
            $display("Datastream error mode %d; Expected: %X, Read: %X", ptg_mode, expected, ptg_row);
         end
      end
      
      return;
   endtask : monitor_datastream
   
   initial begin
      forever begin
         monitor_datastream();
      end
   end
   
endmodule
