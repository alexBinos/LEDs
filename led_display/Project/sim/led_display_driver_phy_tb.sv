`timescale 1ns / 1ps

module led_display_driver_phy_tb #(
   parameter integer SYS_CLK_FREQ       = 100_000_000,
   parameter integer NUM_ROW_PIXELS     = 32,
   parameter integer NUM_COL_PIXELS     = 64,
   parameter integer BCLK_FREQ          = 21_000_000
)(
   input  wire clk_in,
   input  wire n_reset_in
);
   
   import led_display_package::*;
   
   typedef enum logic [3:0] {
      p_count,
      p_shifted,
      p_random,
      p_test
   } pattern_t;
   
   //---------------------------------------------------------
   //                         Signals                       --
   //---------------------------------------------------------
   
   logic          drv_valid;
   logic          drv_done;
   logic          drv_ready;
   pxl_col_t      drv_row_top;
   pxl_col_t      drv_row_bot;
   logic [2:0]    drv_bit_top;
   logic [2:0]    drv_bit_bot;
   logic          drv_bclk;
   logic          drv_latch;
   
   // TODO: Consolidate into array
   pxl_col_t frame_top[$];
   pxl_col_t frame_bot[$];
   
   int num_tests;
   
   //---------------------------------------------------------
   //                   UUT - Display Driver PHY            --
   //---------------------------------------------------------
   
   led_display_driver_phy #(
         .WRITE_FREQ          ( BCLK_FREQ ),
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ),
         .NUM_COLS            ( NUM_COL_PIXELS ))
      led_display_driver_phy_uut (
         .clk_in              ( clk_in ),
         .n_reset_in          ( n_reset_in ),
         
         .row_valid_in        ( drv_valid ),
         .row_top_in          ( drv_row_top ),
         .row_bot_in          ( drv_row_bot ),
         .row_ready_out       ( drv_ready ),
         
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
         .VERBOSE    ( 0 ))
      display_sim_inst (
         .bclk       ( drv_bclk ),
         .rgb_top    ( drv_bit_top ),
         .rgb_bot    ( drv_bit_bot ),
         .addr_in    ( 4'h0 ),
         .oe_in      (  ),
         .le_in      ( drv_latch ));
   
   //---------------------------------------------------------
   //                         Tests                         --
   //---------------------------------------------------------
   
   task test_00 (output bit pass);
      $display("LED display driver PHY Test 00: Basic vectors");
      
      display_sim_inst.reset();
      
      sim_load_frame(p_count);
      driver_write_phy();
      sim_check_frame(pass);
      
      # 1000
      
      display_sim_inst.reset();
      
      sim_load_frame(p_shifted);
      driver_write_phy();
      sim_check_frame(pass);
      
      if (pass) begin
         $display("Pass");
      end
      else begin
         $display("Fail");
      end
      
      return;
   endtask
   
   task test_01 (output bit pass);
      $display("LED display driver PHY, Test 01: Random vectors");
      
      display_sim_inst.reset();
      
      sim_load_frame(p_random);
      driver_write_phy();
      sim_check_frame(pass);
      
      if (pass) begin
         $display("Pass");
      end
      else begin
         $display("Fail");
      end
      
      return;
   endtask : test_01
   
   //---------------------------------------------------------
   //                   Simulation Tasks                    --
   //---------------------------------------------------------
   
   task sim_init();
      num_tests = 10;
   endtask : sim_init
   
   task set_num_test(input int n);
      num_tests = n;
   endtask : set_num_test
   
   task sim_load_frame(input pattern_t p);
      pxl_col_t t;
      
      case (p)
         p_count : begin
            for (int i = 0; i < num_tests; i++) begin
               t.red     = i;
               t.green   = i;
               t.blue    = i;
               frame_top.push_back(t);
               frame_bot.push_back(t);
            end
         end
         
         p_shifted : begin
            for (int i = 0; i < NUM_COL_PIXELS; i++) begin
               t.red     = (1 << i);
               t.green   = (1 << i);
               t.blue    = (1 << i);
               frame_top.push_back(t);
               frame_bot.push_back(t);
            end
         end
         
         p_random : begin
            for (int i = 0; i < num_tests; i++) begin
               std::randomize(t);
               frame_top.push_back(t);
               std::randomize(t);
               frame_bot.push_back(t);
            end
         end
         
         p_test : begin
            for (int i = 0; i < num_tests; i++) begin
               t.red     = 64'hFFFFFFFF_FFFFFFFF;
               t.green   = 64'hFFFFFFFF_FFFFFFFF;
               t.blue    = 64'hFFFFFFFF_FFFFFFFF;
               // t.red     = 64'h80000000_00000001;
               // t.green   = 64'h00000000_00000000;
               // t.blue    = 64'h00000000_00000000;
               frame_top.push_back(t);
               frame_bot.push_back(t);
            end
         end
         
      endcase
      
      return;
   endtask : sim_load_frame
   
   task sim_check_frame(output bit pass);
      pxl_col_t phy_frame;
      pxl_col_t display_frame;
      bit pass_local = 1;
      bit test;
      
      int s = frame_top.size();
      
      for (int i = 0; i < s; i++) begin
         phy_frame = frame_top.pop_front();
         display_frame = display_sim_inst.frame_top.pop_front();
         test = (phy_frame == display_frame);
         assert(test) else $display("Frame error: %X ;; %X", phy_frame, display_frame);
         pass_local &= test;
         
         phy_frame = frame_bot.pop_front();
         display_frame = display_sim_inst.frame_bot.pop_front();
         test = (phy_frame == display_frame);
         assert(test) else $display("Frame error: %X ;; %X", phy_frame, display_frame);
         pass_local &= test;
      end
      
      pass = pass_local;
      
      return;
   endtask : sim_check_frame
   
   task driver_write_phy();
      int s = frame_top.size();
      
      assert(s == frame_bot.size()) else $warning("Top and bottom frame size \
      mismatch: %d, %d", frame_top.size(), frame_bot.size());
      
      for (int i = 0; i < s; i++) begin
         driver_write_row(frame_top[i], frame_bot[i]);
      end
      #10000
      return;
   endtask : driver_write_phy
   
   task driver_write_row(
         input pxl_col_t pxl_top, 
         input pxl_col_t pxl_bot);
      
      driver_wait_for_ready();
      
      drv_row_top = pxl_top;
      drv_row_bot = pxl_bot;
      
      drv_valid = 1'b0;
      @(posedge clk_in);
      drv_valid = 1'b1;
      @(posedge clk_in);
      drv_valid = 1'b0;
      
      return;
   endtask : driver_write_row
   
   task driver_wait_for_ready();
      int timeout = 0;
      do 
      begin
         @(posedge clk_in);
         timeout++;
         if (timeout > 1000000) begin
            $warning("Display driver took too long to complete");
            break;
         end
      end
      while(!drv_ready);
      
      return;
   endtask : driver_wait_for_ready
   
endmodule
