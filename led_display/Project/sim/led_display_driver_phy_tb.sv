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
      p_random
   } pattern_t;
   
   //---------------------------------------------------------
   //                         Signals                       --
   //---------------------------------------------------------
   
   logic                                  drv_enable;
   logic                                  drv_done;
   logic                                  drv_ready;
   logic [2:0][(NUM_COL_PIXELS - 1):0]    drv_pxl_top;
   logic [2:0][(NUM_COL_PIXELS - 1):0]    drv_pxl_bot;
   logic [2:0]                            drv_bit_top;
   logic [2:0]                            drv_bit_bot;
   logic                                  drv_bclk;
   
   // TODO: Consolidate into array
   pxl_col_t frame_top[$];
   pxl_col_t frame_bot[$];
   
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
         .enable_in           ( drv_enable ),
         .ready_out           ( drv_ready ),
         
         .col_top_in          ( drv_pxl_top ),
         .col_bot_in          ( drv_pxl_bot ),
         
         .rgb_top_out         ( drv_bit_top ),
         .rgb_bot_out         ( drv_bit_bot ),
         .bit_clk_out         ( drv_bclk ));
   
   //---------------------------------------------------------
   //                   Sim - Display Module                --
   //---------------------------------------------------------
   
   display_sim display_sim_inst (
      .bclk       ( drv_bclk ),
      .rgb_top    ( drv_bit_top ),
      .rgb_bot    ( drv_bit_bot ),
      .addr_in    ( 4'h0 ),
      .oe_in      (  ),
      .le_in      (  ));
   
   //---------------------------------------------------------
   //                         Tests                         --
   //---------------------------------------------------------
   
   task test_00 (output bit pass);
      $display("LED display driver PHY Test 00: Basic test");
      /*
      sim_load_frame(p_count);
      driver_write_phy();
      sim_check_frame(pass);
      */
      sim_load_frame(p_shifted);
      driver_write_phy();
      sim_check_frame(pass);
      
      return;
   endtask
   
   // TODO: Implement random test
   task test_01 (output bit pass);
      $display("LED display driver PHY, Test 01");
      
      driver_write_phy();
      sim_check_frame(pass);
      return;
   endtask : test_01
   
   //---------------------------------------------------------
   //                   Simulation Tasks                    --
   //---------------------------------------------------------
   
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
   
   task driver_write_row(
         input pxl_col_t pxl_top, 
         input pxl_col_t pxl_bot);
      
      drv_pxl_top = pxl_top;
      drv_pxl_bot = pxl_bot;
      
      drv_enable = 1'b0;
      @(posedge clk_in);
      drv_enable = 1'b1;
      @(posedge clk_in);
      drv_enable = 1'b0;
      driver_wait_for_ready();
      return;
   endtask : driver_write_row
   
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
   
   task sim_load_frame(input pattern_t p);
      pxl_col_t t;
      
      case (p)
         p_count : begin
            for (int i = 0; i < NUM_ROW_PIXELS; i++) begin
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
            for (int i = 0; i < NUM_ROW_PIXELS; i++) begin
               std::randomize(t.red);
               std::randomize(t.green);
               std::randomize(t.blue);
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
      
      for (int i = 0; i < NUM_ROW_PIXELS; i++) begin
         phy_frame = frame_top.pop_front();
         display_frame = display_sim_inst.frame_top.pop_front();
         pass_local &= (phy_frame == display_frame);
         
         phy_frame = frame_bot.pop_front();
         display_frame = display_sim_inst.frame_bot.pop_front();
         pass_local &= (phy_frame == display_frame);
      end
      
      $display("Checker pass: %b", pass_local);
      
      pass = pass_local;
      
      return;
   endtask : sim_check_frame
   
endmodule
