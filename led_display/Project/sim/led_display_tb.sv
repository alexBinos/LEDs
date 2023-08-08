`timescale 1ns / 1ps

module led_display_tb();
   
   localparam integer SYS_CLK_FREQ      = 12_500_000;                        // Basys 3 on board clock frequency (Hz)
   localparam integer HALF_CLK_PERIOD   = 40;                                  // (ns)
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
   
   bit pass;
   bit pass_local;
   
   //---------------------------------------------------------
   //                   UUT - Display Driver                --
   //---------------------------------------------------------
/*
   led_display_driver_phy_tb #(
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ),
         .NUM_ROW_PIXELS      ( NUM_ROW_PIXELS ),
         .NUM_COL_PIXELS      ( NUM_COL_PIXELS ),
         .BCLK_FREQ           ( 25_000_000 ))
      led_display_driver_phy_uut (
         .clk_in     ( clk ),
         .n_reset_in ( nrst ));
   
   led_display_pattern_gen_tb #(
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ))
      led_display_pattern_gen_uut (
         .clk_in     ( clk ),
         .n_reset_in ( nrst ));
   
   led_display_pwm_gen_tb #(
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ),
         .PWM_FREQ            ( 100_000 ))
      led_display_pwm_gen_uut (
         .clk_in     ( clk ),
         .n_reset_in ( nrst ));
   
   led_display_driver_tb #(
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ),
         .PWM_FREQ            ( 100_000 ))
      led_display_driver_uut (
         .clk_in     ( clk ),
         .n_reset_in ( nrst ));
   */
   led_display_ram_tb #(
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ))
      led_display_driver_ram_uut (
         .clk_in     ( clk ),
         .n_reset_in ( nrst ));
   
   //---------------------------------------------------------
   //                            Main                       --
   //---------------------------------------------------------
   
   initial begin : main
      $display("SIMULATION RUNNING");
      
      reset();
      pass = 1;
      
      
      led_display_driver_ram_uut.sim_init();
      led_display_driver_ram_uut.test_00(pass_local);
      pass &= pass_local;
      
     /* 
      led_display_driver_uut.sim_init();
      led_display_driver_uut.set_num_test(5);
      led_display_driver_uut.test_00(pass_local);
      pass &= pass_local;
      
      
      led_display_driver_phy_uut.set_num_test(100);
      
      # 1000
      
      led_display_driver_phy_uut.test_00(pass_local);
      pass &= pass_local;
      
      led_display_driver_phy_uut.test_01(pass_local);
      pass &= pass_local;
      
      led_display_pattern_gen_uut.sim_init();
      led_display_pattern_gen_uut.set_num_test(20);
      
      led_display_pattern_gen_uut.test_00(pass_local);
      pass &= pass_local;
      
      // led_display_pattern_gen_uut.test_01(pass_local);
      // pass &= pass_local;
      
      // led_display_pattern_gen_uut.test_02(pass_local);
      // pass &= pass_local;
      
      
      led_display_pwm_gen_uut.sim_init();
      led_display_pwm_gen_uut.set_num_test(5);
      
      led_display_pwm_gen_uut.test_00(pass_local);
      pass &= pass_local;
      
      */
      
      if (pass) begin
         $display("Overall test: Pass");
      end
      else begin
         $display("Overall test: Fail");
      end
      
      $stop();
   end : main
   
   //---------------------------------------------------------
   //                   Simulation Tasks                    --
   //---------------------------------------------------------
   
   task reset();
      nrst = 1'b0;
      # 100
      nrst = 1'b1;
   endtask : reset
   
endmodule
