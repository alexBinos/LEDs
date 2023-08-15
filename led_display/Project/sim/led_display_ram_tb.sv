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
   
   logic [31:0]   ram_addrb;
   logic [31:0]   ram_dinb;
   logic [31:0]   ram_doutb;
   logic          ram_rstb_busy;
   
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
   logic [3:0] drv_address;
   
   int num_tests;
   
   rgb_row_t expected[$];
   
   //---------------------------------------------------------
   //                         Frame RAM                     --
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
      .addrb      ( {ram_addrb[29:0], 2'b00} ),
      .dinb       ( ram_dinb ),
      .doutb      ( ram_doutb ),
      .rsta_busy  (  ),
      .rstb_busy  ( ram_rstb_busy )); 
    
   //---------------------------------------------------------
   //             DUT - LED Display RAM Controller          --
   //---------------------------------------------------------
   
   led_display_ram_control dut (
      .clk_in           ( clk_in ),
      .n_reset_in       ( n_reset_in ),
      .ram_address_out  ( ram_addrb ),
      .ram_rdata_in     ( ram_doutb ),
      .row_out          ( row ),
      .row_valid_out    ( row_valid ),
      .row_address_out  ( row_addr ),
      .row_ready_in     ( (row_ready && !ram_rstb_busy && ram_control_ready) ));
   
   //---------------------------------------------------------
   //                PHY and Display Model                  --
   //---------------------------------------------------------
   
   led_display_driver_phy #(
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ))
      drv (
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
         .address_out         ( drv_address ));
   
   display_sim #(
         .NUM_COLS   ( NUM_COL_PIXELS ),
         .NUM_ROWS   ( NUM_ROW_PIXELS ),
         .VERBOSE    ( VERBOSE ))
      display_sim_inst (
         .bclk       ( drv_bclk ),
         .rgb_top    ( drv_bit_top ),
         .rgb_bot    ( drv_bit_bot ),
         .addr_in    ( drv_address ),
         .oe_in      (  ),
         .le_in      ( drv_latch ));
   
   //---------------------------------------------------------
   //                         Tests                         --
   //---------------------------------------------------------
   
   task test_00 (output bit pass);
      $display("LED display memory controller Test 00: ");
      
      ram_control_ready = 1'b0;
      
      # 100
      drive();
      # 100
      
      ram_control_ready = 1'b1;
      
      # 300000
      
      check(pass);
      
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
      ram_wena = 4'h0;
      ram_addra = {32{1'b0}};
      ram_dina = {32{1'b0}};
      expected.delete();
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
   
   task automatic drive();
      rgb_row_t r;
      int addr = 0;
      
      expected.delete();
      
      for (int j = 0; j < 16; j++) begin
         std::randomize(r);
         expected.push_back(r);
         for (int p = 11; p >= 0; p--) begin
            sim_write_ram(r[(32 * p)+:32], addr);
            addr += 4;
         end
      end
      
      return;
   endtask : drive
   
   task automatic sim_write_ram(input logic [31:0] data, input logic [31:0] addr);
      sim_cycles(1);
      ram_dina = data;
      ram_addra = addr;
      ram_wena = 4'hF;
      sim_cycles(1);
      ram_wena = 4'h0;
      
      return;
   endtask : sim_write_ram
   
   //---------------------------------------------------------
   //                      Checker                          --
   //---------------------------------------------------------
   
   task automatic check(output bit pass);
      rgb_row_t r;
      logic [3:0] a;
      int n;
      bit pass_local;
      pass = 1'b1;
      
      n = display_sim_inst.frame.size();
      for (int i = 0; i < n; i++) begin
         r = display_sim_inst.frame.pop_front();
         a = display_sim_inst.address.pop_front();
         pass_local = (r == expected[a]);
         pass &= pass_local;
         assert(pass_local) else $display("Checker error at address %X", a);
      end
      
      if (VERBOSE) $display("Checker tested %d addresses", n);
      
      return;
   endtask : check
   
endmodule
