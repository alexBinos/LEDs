/*
   Top level project for 64x32 pixel RGB LED display driver.
   Designed to run on the Digilent BASYS3 Artix 7 development card.
*/

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
   localparam integer NUM_ROWS       = 32;            // Number of rows on LED display
   localparam integer NUM_COLS       = 64;            // Number of columns on LED display
   localparam integer WRITE_FREQ     = 20_000_000;    // Display bit clock frequency (16MHz)
   localparam integer FADE_TIME      = 10_000_000;    // RGB fade mode transition time (5ms)
   
   //---------------------------------------------------------
   //                Variables and Signals                  --
   //---------------------------------------------------------
   
   // System
   wire           clk100MHz;
   wire           nrst;
   wire           blink_led;
   
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
   wire           latch_enable;
   wire           output_enable;
   wire [3:0]     addr;
   
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
   //---------------------------------------------------------
   //                      Display Driver                  --
   //---------------------------------------------------------
   
   led_display_driver #(
         .NUM_ROWS            ( NUM_ROWS ),
         .NUM_COLS            ( NUM_COLS ),
         .WRITE_FREQ          ( WRITE_FREQ ),
         .FADE_TIME           ( FADE_TIME ),
         .BOUNCE_FREQ         ( 64 ),
         .SYS_CLK_FREQ        ( SYS_CLK_FREQ ))
      led_display_driver_inst (
         .clk_in              ( clk100MHz ),
         .n_reset_in          ( nrst ),
         .mode_in             ( mode ),
         .colour_in           ( manual_colour ),
         .latch_enable_out    ( latch_enable ),
         .output_enable_out   ( output_enable ),
         .addr_out            ( addr ),
         .rgb_top_out         ( {R1, G1, B1} ),
         .rgb_bot_out         ( {R2, G2, B2} ),
         .bit_clk_out         ( BCLK ));
   
   assign mode                    = SW[3:0];
   assign manual_colour[2]        = SW[4];
   assign manual_colour[1]        = SW[5];
   assign manual_colour[0]        = SW[6];
   assign LAT                     = SW[7] ? latch_enable : SW[8];
   assign OE                      = SW[7] ? output_enable : SW[9];
   assign {A, B, C, D}            = SW[10] ? addr[3:0] : SW[14:11];
   
   
   //---------------------------------------------------------
   //                         Debug                         --
   //---------------------------------------------------------
   
   blink #(
         .SYS_CLK_FREQ  ( SYS_CLK_FREQ ),
         .BLINK_FREQ    ( 2 ))
      blink_inst (
         .clk_in        ( clk100MHz ),
         .n_reset_in    ( nrst ),
         .led_out       ( blink_led ));
   
   assign LED_DEBUG[15] = blink_led;
   
   assign LED_DEBUG[8] = LAT;
   assign LED_DEBUG[9] = OE;
   
endmodule
