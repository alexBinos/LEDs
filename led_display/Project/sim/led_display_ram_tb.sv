`timescale 1ns / 1ps

module led_display_ram_tb #(
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
   
   logic          ram_write_en;
   logic [31:0]   ram_addr;
   logic [31:0]   ram_din;
   logic [31:0]   ram_dout;
   logic          ram_rst_busy;
   
   logic [31:0]   ram_addra;
   logic [31:0]   ram_dina;
   logic [31:0]   ram_douta;
   logic [3:0]    ram_wena;
   
   logic ram_control_ready;
   
   rgb_row_t      row;
   logic [3:0]    row_addr;
   logic          row_ready;
   logic          row_ready;
   
   logic [2:0] drv_bit_top;
   logic [2:0] drv_bit_bot;
   logic       drv_bclk;
   logic       drv_latch;
   logic [3:0] drv_addr;
   
   int num_tests;
   
   int address_error_count;
   int data_error_count;
   
   //---------------------------------------------------------
   //                   UUT - Display Driver PHY            --
   //---------------------------------------------------------
   
   frame_ram frame_ram_inst (
      .clka       ( clk_in ),
      .rsta       ( !n_reset_in ),
      .wea        ( ram_wena ),
      .addra      ( ram_addra ),
      .dina       ( ram_dina ),
      .douta      ( ram_douta ),
      
      .clkb       ( clk_in ),
      .rstb       ( !n_reset_in ),
      .web        ( 4'h0 ),
      .addrb      ( {ram_addr[29:0], 2'b00} ),
      .dinb       ( ram_din ),
      .doutb      ( ram_dout ),
      .rsta_busy  (  ),
      .rstb_busy  ( ram_rst_busy ));
   
   led_display_ram_control dut (
      .clk_in           ( clk_in ),
      .n_reset_in       ( n_reset_in ),
      .ram_address_out  ( ram_addr ),
      .ram_rdata_in     ( ram_dout ),
      .row_out          ( row ),
      .row_valid_out    ( row_valid ),
      .row_address_out  ( row_addr ),
      .row_ready_in     ( (row_ready && !ram_rst_busy) ));
   
   led_display_driver_phy #(
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ))
      dut_drv (
         .clk_in              ( clk_in ),
         .n_reset_in          ( n_reset_in ),
         
         .row_in              ( row ),
         .row_valid_in        ( row_valid ),
         .row_ready_out       ( row_ready ),
         .row_address_in      ( row_addr ),
         
         .latch_out           ( drv_latch ),
         .red_top_out         ( drv_bit_top[0] ),
         .green_top_out       ( drv_bit_top[1] ),
         .blue_top_out        ( drv_bit_top[2] ),
         .red_bot_out         ( drv_bit_bot[0] ),
         .green_bot_out       ( drv_bit_bot[1] ),
         .blue_bot_out        ( drv_bit_bot[2] ),
         .bit_clk_out         ( drv_bclk ),
         .addr_out            ( drv_addr ));
   
   //---------------------------------------------------------
   //                         Tests                         --
   //---------------------------------------------------------
   
   task test_00 (output bit pass);
      $display("LED display memory controller Test 00: ");
      
      pass = 1;
      
      ram_control_ready = 1'b0;
      
      # 100
      /*
      ram_wena = 4'hF;
      ram_addra = 0;
      ram_dina = 32'h11111111;
      */
      # 20000
      
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
      ram_write_en = 1'b0;
      ram_wena = 4'h0;
      ram_addra = {32{1'b0}};
      ram_dina = {32{1'b0}};
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
      
   endtask : reset_error_counters
   
   //---------------------------------------------------------
   //                         Driver                        --
   //---------------------------------------------------------
   
   //---------------------------------------------------------
   //                      Monitors                         --
   //---------------------------------------------------------

   
endmodule
