/*
   Top level project for 64x32 pixel RGB LED display driver.
   Designed to run on the Digilent BASYS3 Artix 7 development card.
*/

import led_display_package::*;

module led_display (
   // Global
   input  wire          FPGA_nRESET,   // Reset switch
   input  wire          FPGA_CLK,      // Onboard 100MHz clock
   
   // LED display control
   output wire          R1,            // Top red value
   output wire          G1,            // Top green value
   output wire          B1,            // Top blue value
   output wire          R2,            // Bottom red value
   output wire          G2,            // Bottom green value
   output wire          B2,            // Bottom blue value
   output wire          LAT,           // Data latch
   output wire          OE,            // Output enable
   output wire          BCLK,          // Bit clock
   output wire          A,             // Row address[0]
   output wire          B,             // Row address[1]
   output wire          C,             // Row address[2]
   output wire          D,             // Row address[3]
   
   // Debug
   input  wire [15:0]   SW,
   output wire [15:0]   LED_DEBUG
);
   
   //---------------------------------------------------------
   //             Local Parameters and Types                --
   //---------------------------------------------------------
   
   localparam integer SYS_CLK_FREQ   = 100_000_000;   // Basys 3 board clock frequency (100MHz)
   localparam integer DISP_CLK_FREQ  = 20_000_000;    // Display clock frequency
   localparam integer NUM_ROWS       = 32;            // Number of rows on LED display
   localparam integer NUM_COLS       = 64;            // Number of columns on LED display
   
   //---------------------------------------------------------
   //                Variables and Signals                  --
   //---------------------------------------------------------
   
   // System
   wire           clk100MHz;
   wire           clk20MHz;
   wire           nrst;
   wire           blink_led;
   wire           pll_locked;
   
   // RAM control
   wire           ram_clk;
   wire           ram_enable;
   wire           ram_write_enable;
   wire [15:0]    ram_addr;
   wire [23:0]    ram_data_in;
   wire [23:0]    ram_data_out;
   
   // Display driver control
   wire [3:0]     mode;
   wire [2:0]     manual_colour;
   wire [3:0]     addr;
   wire           latch_enable;
   
   rgb_row_t      row;
   wire           row_valid;
   wire           row_ready;
   
   //---------------------------------------------------------
   //                   Clocking and Resets                 --
   //---------------------------------------------------------
   
   assign clk100MHz = FPGA_CLK;
   assign nrst = !FPGA_nRESET;
   
   //---------------------------------------------------------
   //                   Memory Controller                  --
   //---------------------------------------------------------
   /*
   frame_ram frame_ram_inst (
      .clka    ( ram_clk ),
      .ena     ( ram_enable ),
      .wea     ( ram_write_enable ),
      .addra   ( ram_addr ),
      .dina    ( ram_data_in ),
      .douta   ( ram_data_out ));
   */
   
   display_pll display_pll_inst (
     .clk_in1  ( clk100MHz ),
     .resetn   ( nrst ),
     .clk_out1 ( clk20MHz ),
     .locked   ( pll_locked ));
   
   //---------------------------------------------------------
   //                      Display Driver                  --
   //---------------------------------------------------------
   
   led_display_pattern_gen #(
         .SYS_CLK_FREQ        ( DISP_CLK_FREQ ),
         .SIMULATION          ( 0 ))
      ptg (
         .clk_in              ( clk20MHz ),
         .n_reset_in          ( nrst ),
         .colour_in           ( manual_colour ),
         .mode_in             ( mode ),
         .row_out             ( row ),
         .row_valid_out       ( row_valid ),
         .row_ready_in        ( row_ready ),
         .row_address_out     ( addr ));
   
   led_display_driver_phy #(
         .SYS_CLK_FREQ        ( DISP_CLK_FREQ ))
      drv (
         .clk_in              ( clk20MHz ),
         .n_reset_in          ( nrst ),
         
         .row_in              ( row ),
         .row_valid_in        ( row_valid ),
         .row_ready_out       ( row_ready ),
         
         .latch_out           ( latch_enable ),
         .red_top_out         ( R1 ),
         .green_top_out       ( G1 ),
         .blue_top_out        ( B1 ),
         .red_bot_out         ( R2 ),
         .green_bot_out       ( G2 ),
         .blue_bot_out        ( B2 ),
         .bit_clk_out         ( BCLK ));
   
   assign mode[3:0]               = SW[3:0];
   assign manual_colour[2:0]      = SW[6:4];
   assign OE                      = !latch_enable;
   assign LAT                     = latch_enable;
   assign {D, C, B, A}            = SW[11] ? SW[15:12] : addr[3:0];
   
   //---------------------------------------------------------
   //                         Debug                         --
   //---------------------------------------------------------
   
   blink #(
         .SYS_CLK_FREQ  ( DISP_CLK_FREQ ),
         .BLINK_FREQ    ( 2 ))
      blink_inst (
         .clk_in        ( clk20MHz ),
         .n_reset_in    ( nrst ),
         .led_out       ( blink_led ));
   
   assign LED_DEBUG[15] = blink_led;
   assign LED_DEBUG[14] = pll_locked;
   
   assign LED_DEBUG[7] = OE;
   assign LED_DEBUG[8] = LAT;
   
endmodule
