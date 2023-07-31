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
   
   localparam integer HALF_CLK_PERIOD   = 5;                                  // (ns)
   localparam integer NUM_PIXELS        = NUM_ROW_PIXELS * NUM_COL_PIXELS;    // Total number of pixels in the array
   localparam integer REFRESH_CYCLES    = BCLK_FREQ / (NUM_PIXELS / 2);       // Number of bit clocks per display refresh
   
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
      
      driver_phy_test();
      
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
         input bit [2:0][(NUM_COL_PIXELS - 1):0] pxl_top, 
         input bit [2:0][(NUM_COL_PIXELS - 1):0] pxl_bot);
      drv_pxl_top = pxl_top;
      drv_pxl_bot = pxl_bot;
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
      
      drv_write_row(64'h112233445566_778899AABBCC, 64'hFFEEDDCC_BBAA9988);
      
      #10000
      return;
   endtask
   
endmodule
