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
   logic [3:0] drv_addr;
   
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
         .row_address_in      ( ptg_row_address ),
         
         .latch_out           ( drv_latch ),
         .red_top_out         ( drv_bit_top[0] ),
         .green_top_out       ( drv_bit_top[1] ),
         .blue_top_out        ( drv_bit_top[2] ),
         .red_bot_out         ( drv_bit_bot[0] ),
         .green_bot_out       ( drv_bit_bot[1] ),
         .blue_bot_out        ( drv_bit_bot[2] ),
         .bit_clk_out         ( drv_bclk ),
         .address_out         ( drv_addr ));
   
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
         .addr_in    ( drv_addr ),
         .oe_in      ( !drv_latch ),
         .le_in      ( drv_latch ));
   
   //---------------------------------------------------------
   //                         Tests                         --
   //---------------------------------------------------------
   
   task test_00 (output bit pass);
      $display("LED display pattern generator Test 00: Basic patterns");
      
      pass = 1;
      
      drive(dut_ptg.MODE_SOLID, 1);
      
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
      display_sim_inst.reset();
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
      
endmodule
