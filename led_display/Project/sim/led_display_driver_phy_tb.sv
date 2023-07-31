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
   
   task test_00 ();
      $display("LED display driver PHY, Test 00");
      
      sim_load_frame();
      
      
      driver_phy_test();
      
      sim_check_frame();
      
      return;
   endtask
   
   //---------------------------------------------------------
   //                   Simulation Tasks                    --
   //---------------------------------------------------------
   
   task drv_wait_ready();
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
   endtask
   
   task drv_write_row(
         input pxl_col_t pxl_top, 
         input pxl_col_t pxl_bot);
         
      drv_pxl_top[0][63:0] = pxl_top.red;
      drv_pxl_top[1][63:0] = pxl_top.green;
      drv_pxl_top[2][63:0] = pxl_top.blue;
      drv_pxl_bot[0][63:0] = pxl_bot.red;
      drv_pxl_bot[1][63:0] = pxl_bot.green;
      drv_pxl_bot[2][63:0] = pxl_bot.blue;
      
      drv_enable = 1'b0;
      @(posedge clk_in);
      drv_enable = 1'b1;
      @(posedge clk_in);
      drv_enable = 1'b0;
      drv_wait_ready();
      return;
   endtask
   
   task driver_phy_test();
      $display("Running PHY test");
      
      for (int i = 0; i < NUM_ROW_PIXELS; i++) begin
         drv_write_row(frame_top[i], frame_bot[i]);
      end
      
      #10000
      return;
   endtask
   
   task sim_load_frame();
      pxl_col_t t;
      
      for (int i = 0; i < NUM_ROW_PIXELS; i++) begin
         t.red     = i;
         t.green   = i;
         t.blue    = i;
         frame_top.push_back(t);
         frame_bot.push_back(t);
      end
      
      return;
   endtask : sim_load_frame
   
   task sim_check_frame();
      pxl_col_t phy_frame;
      pxl_col_t display_frame;
      bit pass_local = 1;
      
      for (int i = 0; i < NUM_ROW_PIXELS; i++) begin
         phy_frame = frame_top.pop_front();
         display_frame = display_sim_inst.frame.pop_front();
         pass_local &= (phy_frame.red == display_frame.red);
         
         $display(phy_frame.red);
         $display(display_frame.red);
         $display("Pass: %b", pass_local);
      end
      
   endtask : sim_check_frame
   
endmodule
