`timescale 1ns / 1ps

module led_display_tb();
   
   localparam integer SYS_CLK_FREQ      = 100_000_000;                        // Basys 3 on board clock frequency (Hz)
   localparam integer HALF_CLK_PERIOD   = 5;                                  // (ns)
   localparam integer NUM_ROW_PIXELS    = 32;                                 // Number of row pixels
   localparam integer NUM_COL_PIXELS    = 64;                                 // Number of column pixels
   localparam integer NUM_PIXELS        = NUM_ROW_PIXELS * NUM_COL_PIXELS;    // Total number of pixels in the array
   localparam integer BCLK_FREQ         = 21_000_000;                         // Bit clock frequency
   localparam integer REFRESH_CYCLES    = BCLK_FREQ / (NUM_PIXELS / 2);       // Number of bit clocks per display refresh
   
   //---------------------------------------------------------
   //                   Clocking and Resets                 --
   //---------------------------------------------------------
   
   bit nrst;
   bit clk;
   initial forever #(HALF_CLK_PERIOD) clk = ~clk;
   
   //---------------------------------------------------------
   //                         Signals                       --
   //---------------------------------------------------------
   
   logic          ram_clk;
   logic          ram_enable;
   logic          ram_write_enable;
   logic [15:0]   ram_addr;
   logic [23:0]   ram_data_in;
   logic [23:0]   ram_data_out;
   
   logic          drv_enable;
   logic          drv_done;
   logic          drv_ready;
   logic [2:0][(NUM_COL_PIXELS - 1):0]   drv_pxl_top;
   logic [2:0][(NUM_COL_PIXELS - 1):0]   drv_pxl_bot;
   logic [2:0]    drv_bit_top;
   logic [2:0]    drv_bit_bot;
   logic          drv_bclk;
   
   logic [3:0]    disp_mode;
   logic [2:0]    disp_colour;
   logic          disp_le;
   logic          disp_oe;
   logic [3:0]    disp_addr;
   logic [2:0]    disp_rgb_top;
   logic [2:0]    disp_rgb_bot;
   logic          disp_bclk;
   
   logic [7:0]    pwm_colour_in;
   logic          pwm_colour_out;
   
   //---------------------------------------------------------
   //                UUT - Memory Controller                --
   //---------------------------------------------------------
   
   assign ram_clk = clk;
   
   frame_ram frame_ram_sim (
      .clka    ( ram_clk ),
      .ena     ( ram_enable ),
      .wea     ( ram_write_enable ),
      .addra   ( ram_addr ),
      .dina    ( ram_data_in ),
      .douta   ( ram_data_out ));
   
   //---------------------------------------------------------
   //                   UUT - Display Driver                --
   //---------------------------------------------------------
   
   led_display_driver #(
         .NUM_ROWS            ( NUM_ROW_PIXELS ),
         .NUM_COLS            ( NUM_COL_PIXELS ),
         .WRITE_FREQ          ( BCLK_FREQ ),
         .FADE_TIME           ( 10_000 ),
         .BOUNCE_FREQ         ( 10_000 ),
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ))
      led_display_driver_uut (
         .clk_in              ( clk ),
         .n_reset_in          ( nrst ),
         .mode_in             ( disp_mode ),
         .colour_in           ( disp_colour ),
         .latch_enable_out    ( disp_le ),
         .output_enable_out   ( disp_oe ),
         .addr_out            ( disp_addr ),
         .rgb_top_out         ( disp_rgb_top ),
         .rgb_bot_out         ( disp_rgb_bot ),
         .bit_clk_out         ( disp_bclk ));
   
   led_display_driver_phy #(
         .WRITE_FREQ          ( BCLK_FREQ ),
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ))
      led_display_driver_phy_uut (
         .clk_in              ( clk ),
         .n_reset_in          ( nrst ),
         .enable_in           ( drv_enable ),
         .ready_out           ( drv_ready ),
         
         .col_top_in          ( drv_pxl_top ),
         .col_bot_in          ( drv_pxl_bot ),
         
         .rgb_top_out         ( drv_bit_top ),
         .rgb_bot_out         ( drv_bit_bot ),
         .bit_clk_out         ( drv_bclk ));
   
   pwm_generator #(
         .SYS_CLK_FREQ     ( SYS_CLK_FREQ ),
         .PWM_FREQ         ( REFRESH_CYCLES ),
         .BIT_W            ( 8 ))
      pwm_generator_uut (
         .clk_in           ( clk ),
         .n_reset_in       ( nrst ),
         .colour_in        ( pwm_colour_in ),
         .pwm_colour_out   ( pwm_colour_out ));
   
   //---------------------------------------------------------
   //                   Sim - Display Module                --
   //---------------------------------------------------------
   /*
   // PHY test
   display_sim display_sim_inst (
      .bclk       ( drv_bclk ),
      .rgb_top    ( drv_bit_top ),
      .rgb_bot    ( drv_bit_bot ),
      .addr_in    (  ),
      .oe_in      (  ),
      .le_in      (  ));
   */
   
   
   display_sim display_sim_inst (
      .bclk       ( disp_bclk ),
      .rgb_top    ( disp_rgb_top ),
      .rgb_bot    ( disp_rgb_top ),
      .addr_in    ( disp_addr ),
      .oe_in      ( disp_oe ),
      .le_in      ( disp_le ));
   
   //---------------------------------------------------------
   //                            Main                       --
   //---------------------------------------------------------
   
   initial begin
      
      $display("SIMULATION RUNNING");
      
      reset();
      
      # 5000
      
      disp_colour = 3'b001;
      disp_mode = 4'h3;
      
      //driver_phy_test();
      
      
      #10000
      $stop();
      
   end
   
   //---------------------------------------------------------
   //                   Simulation Tasks                    --
   //---------------------------------------------------------
   
   task reset();
      nrst = 1'b0;
      # 100
      nrst = 1'b1;
   endtask
   
   // Write a single data word to RAM at a given address
   task ram_write_word(input logic [23:0] addr, input logic [23:0] data);
      @(posedge clk);
      ram_enable         = 1'b1;
      ram_write_enable   = 1'b1;
      ram_addr[23:0]     = addr[23:0];
      ram_data_in[23:0]  = data[23:0];
      @(posedge clk);
      ram_enable         = 1'b0;
      ram_write_enable   = 1'b0;
      return;
   endtask
   
   // Read a single data word from a given address
   // Note: there are 2 dead clock periods where data is invalid
   task ram_read_word(input logic [23:0] addr);
      @(posedge clk);
      ram_addr[23:0]     = addr[23:0];
      ram_enable         = 1'b1;
      ram_write_enable   = 1'b0;
      # 30
      @(posedge clk);
      ram_enable         = 1'b1;
      ram_write_enable   = 1'b0;
      @(posedge clk);
      ram_enable         = 1'b0;
      return;
   endtask
   
   task ram_load_image();
      ram_enable         = 1'b1;
      ram_write_enable   = 1'b1;
      ram_addr           = 24'h000000;
      for (int i = 0; i < NUM_PIXELS; i++) begin
         @(posedge clk);
         ram_data_in[23:0] = i[23:0];
         ram_addr <= ram_addr + 1'b1;
      end
      ram_enable         = 1'b0;
      ram_write_enable   = 1'b0;
      return;
   endtask
   
   task drv_write_row(
         input bit [2:0][(NUM_COL_PIXELS - 1):0] pxl_top, 
         input bit [2:0][(NUM_COL_PIXELS - 1):0] pxl_bot);
      drv_pxl_top = pxl_top;
      drv_pxl_bot = pxl_bot;
      drv_enable = 1'b0;
      @(posedge clk);
      drv_enable = 1'b1;
      @(posedge clk);
      drv_enable = 1'b0;
      drv_wait_ready();
      return;
   endtask
   
   task drv_wait_ready();
      int timeout = 0;
      do 
      begin
         @(posedge clk);
         timeout++;
         if (timeout > 1000000) begin
            $warning("Display driver took too long to complete");
            break;
         end
      end
      while(!drv_ready);
      
      return;
   endtask
   
   task driver_phy_test();
      $display("Running PHY test");
      reset();
      
      # 1000
      
      drv_write_row(64'h112233445566_778899AABBCC, 64'hFFEEDDCC_BBAA9988);
      /*drv_write_pxl(24'h010203, 24'h616263);
      drv_write_pxl(24'h000000, 24'hFFFFFF);
      drv_write_pxl(24'h00DEAD, 24'h00BEEF);
      drv_write_pxl(24'h123456, 24'h789ABC);
      drv_write_pxl(24'h000000, 24'h000000);
      
      reset();
      drv_write_pxl(24'h010203, 24'h616263);
      drv_write_pxl(24'h123456, 24'h789ABC);
      drv_write_pxl(24'h000000, 24'hFFFFFF);
      drv_write_pxl(24'h00DEAD, 24'h00BEEF);
      drv_write_pxl(24'hFFFFFF, 24'hFFFFFF);*/
      
      #10000
      return;
   endtask
   
endmodule
