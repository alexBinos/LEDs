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
   
   logic          row_valid;
   logic          row_ready;
   logic [3:0]    row_address;
   rgb_row_t      row;
   
   logic [2:0]    drv_bit_top;
   logic [2:0]    drv_bit_bot;
   logic          drv_bclk;
   logic          drv_latch;
   logic [3:0]    drv_address;
   
   rgb_row_t      frame[$];
   logic [3:0]    address[$];
   
   int num_tests;
   
   //---------------------------------------------------------
   //                   UUT - Display Driver PHY            --
   //---------------------------------------------------------
   
   led_display_driver_phy #(
         .WRITE_FREQ          ( BCLK_FREQ ),
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ),
         .NUM_COLS            ( NUM_COL_PIXELS ))
      dut (
         .clk_in              ( clk_in ),
         .n_reset_in          ( n_reset_in ),
         
         .row_valid_in        ( row_valid ),
         .row_in              ( row ),
         .row_address_in      ( row_address ),
         .row_ready_out       ( row_ready ),
         
         .latch_out           ( drv_latch ),
         .red_top_out         ( drv_bit_top[0] ),
         .green_top_out       ( drv_bit_top[1] ),
         .blue_top_out        ( drv_bit_top[2] ),
         .red_bot_out         ( drv_bit_bot[0] ),
         .green_bot_out       ( drv_bit_bot[1] ),
         .blue_bot_out        ( drv_bit_bot[2] ),
         .bit_clk_out         ( drv_bclk ),
         .address_out         ( drv_address ));
   
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
         .addr_in    ( drv_address ),
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
   
   task automatic sim_init();
      num_tests = 10;
      row_valid = 1'b0;
      row = {GL_RGB_ROW_W{1'b0}};
      row_address <= {4{1'b0}};
      frame.delete();
      address.delete();
      display_sim_inst.reset();
   endtask : sim_init
   
   task automatic set_num_test(input int n);
      num_tests = n;
      $display("Set number of tests to %d", num_tests);
   endtask : set_num_test
   
   task automatic sim_cycles(int n);
      repeat (n) begin
         @(posedge clk_in);
      end
      #1step;
      return;
   endtask : sim_cycles
   
   task automatic sim_load_frame(input pattern_t p);
      rgb_row_t t;
      int addr = 0;
      
      case (p)
         p_count : begin
            for (int i = 0; i < num_tests; i++) begin
               t.top.red     = i;
               t.top.green   = i;
               t.top.blue    = i;
               t.bot.red     = i;
               t.bot.green   = i;
               t.bot.blue    = i;
               frame.push_back(t);
               address.push_back(addr[3:0]);
               addr++;
            end
         end
         
         p_shifted : begin
            for (int i = 0; i < num_tests; i++) begin
               t.top.red     = (1 << i);
               t.top.green   = (1 << i);
               t.top.blue    = (1 << i);
               t.bot.red     = (1 << i);
               t.bot.green   = (1 << i);
               t.bot.blue    = (1 << i);
               frame.push_back(t);
               address.push_back(addr[3:0]);
               addr++;
            end
         end
         
         p_random : begin
            for (int i = 0; i < num_tests; i++) begin
               std::randomize(t);
               frame.push_back(t);
               address.push_back(addr[3:0]);
               addr++;
            end
         end
         
         p_test : begin
            for (int i = 0; i < num_tests; i++) begin
               t.top.red     = 64'h80000000_00000001;
               t.top.green   = 64'h80000000_00000001;
               t.top.blue    = 64'h80000000_00000001;
               t.bot.red     = 64'h80000000_00000001;
               t.bot.green   = 64'h80000000_00000001;
               t.bot.blue    = 64'h80000000_00000001;
               frame.push_back(t);
               address.push_back(addr[3:0]);
               addr++;
            end
         end
         
      endcase
      
      return;
   endtask : sim_load_frame
   
   task automatic sim_check_frame(output bit pass);
      rgb_row_t      phy_frame;
      rgb_row_t      display_frame;
      logic [3:0]    phy_addr;
      logic [3:0]    display_addr;
      bit            pass_local = 1;
      bit            test;
      
      int s = frame.size();
      
      test = (frame.size() == address.size());
      pass_local &= test;
      assert(test) else begin
         $display("Frame and address size mismatch: %d ;; %d", frame.size(), address.size());
         return;
      end
      
      for (int i = 0; i < s; i++) begin
         phy_frame = frame.pop_front();
         display_frame = display_sim_inst.frame.pop_front();
         test = (phy_frame == display_frame);
         assert(test) else $display("Frame error: %X ;; %X", phy_frame, display_frame);
         pass_local &= test;
      end
      
      for (int i = 0; i < s; i++) begin
         phy_addr = address.pop_front();
         display_addr = display_sim_inst.address.pop_front();
         test = (phy_addr == display_addr);
         assert(test) else $display("Address error: %X ;; %X", phy_addr, display_addr);
         pass_local &= test;
      end
      
      pass = pass_local;
      
      return;
   endtask : sim_check_frame
   
   task automatic driver_write_phy();
      int s = frame.size();
      
      for (int i = 0; i < s; i++) begin
         driver_wait_for_ready();
      
         row = frame[i];
         row_address = address[i];
         row_valid = 1'b0;
         sim_cycles(1);
         row_valid = 1'b1;
         sim_cycles(1);
         row_valid = 1'b0;
         
      end
      
      driver_wait_for_ready();
      
      return;
   endtask : driver_write_phy
   
   task automatic driver_wait_for_ready();
      int timeout = 0;
      do begin
         sim_cycles(1);
         timeout++;
         if (timeout > 1000000) begin
            $warning("Display driver took too long to complete");
            break;
         end
      end
      while(!row_ready);
      
      return;
   endtask : driver_wait_for_ready
   
endmodule
