/*
   Top level project for 64x32 pixel RGB LED display driver.
   Designed to run on the Digilent BASYS3 Artix 7 development card.
*/

module led_display (
   // Global
   input wire FPGA_CLK,       // Onboard 100MHz clock
   input wire FPGA_nRESET,    // Reset switch
   
   // LED display control
   output wire R1,            // Top red value
   output wire G1,            // Top green value
   output wire B1,            // Top blue value
   output wire R2,            // Bottom red value
   output wire G2,            // Bottom green value
   output wire B2,            // Bottom blue value
   output wire LAT,           // Data latch
   output wire OE,            // Output enable
   output wire BCLK,          // Bit clock
   output wire A,             // Row address[0]
   output wire B,             // Row address[1]
   output wire C,             // Row address[2]
   
   // Debug
   input wire [15:0]    SW,
   output wire [15:0]   LED_DEBUG
);
   
   //---------------------------------------------------------
   //             Local Parameters and Types                --
   //---------------------------------------------------------
   
   localparam integer SYS_CLK_FREQ = 100_000_000;
   
   //---------------------------------------------------------
   //                Variables and Signals                  --
   //---------------------------------------------------------
   
   wire clk100MHz;
   wire nrst;
   wire blink_led;
   
   // RAM control
   wire           ram_clk;
   wire           ram_enable;
   wire           ram_write_enable;
   wire [15:0]    ram_addr;
   wire [23:0]    ram_data_in;
   wire [23:0]    ram_data_out;
   
   //---------------------------------------------------------
   //                   Clocking and Resets                 --
   //---------------------------------------------------------
   
   assign clk100MHz = FPGA_CLK;
   assign nrst = FPGA_nRESET;
   
   //---------------------------------------------------------
   //                   Memory Controller                  --
   //---------------------------------------------------------
   
   frame_ram frame_ram_inst (
      .clka    ( ram_clk ),
      .ena     ( ram_enable ),
      .wea     ( ram_write_enable ),
      .addra   ( ram_addr ),
      .dina    ( ram_data_in ),
      .douta   ( ram_data_out ));
   
   //---------------------------------------------------------
   //                      Display Driver                  --
   //---------------------------------------------------------
   
   //---------------------------------------------------------
   //                         Debug                         --
   //---------------------------------------------------------
   /*
   blink blink_inst (
      .clk_in        ( clk100MHz ),
      .n_reset_in    ( nrst ),
      .led_out       ( blink_led ));
   
   assign LED_DEBUG[0] = blink_led;
   */
   
endmodule
