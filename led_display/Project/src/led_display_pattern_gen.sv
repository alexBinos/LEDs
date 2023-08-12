`timescale 1ns / 1ps

module led_display_pattern_gen #(
   parameter integer SYS_CLK_FREQ = 100_000_000,
   parameter integer SIMULATION   = 0
)(
   input  wire       clk_in,
   input  wire       n_reset_in,
   
   input  wire [2:0] colour_in,
   input  wire [3:0] mode_in,
   
   output rgb_row_t  row_out,
   output wire       row_valid_out,
   input  wire       row_ready_in,
   output wire [3:0] row_address_out
);
   
   //---------------------------------------------------------
   //             Local Parameters and Types                --
   //---------------------------------------------------------
   
   localparam integer MODE_OFF          = 0;
   localparam integer MODE_SOLID        = 1;
   localparam integer MODE_SCAN_H       = 2;
   localparam integer MODE_SCAN_V       = 3;
   localparam integer MODE_PULSE        = 4;
   localparam integer DEBUG_V           = 7;
   
   localparam integer EFFECT_TIMER      = SIMULATION ? 1000 : 1_000_000;
   localparam integer PWM_FREQ          = SIMULATION ? 100_000 : 20_000;
   
   //---------------------------------------------------------
   //                Variables and Signals                  --
   //---------------------------------------------------------
   
   rgb_row_t   row;
   reg         row_valid;
   reg [3:0]   row_address;
   reg [3:0]   row_address_buf;
   
   reg [3:0]   mode_buf;
   
   rgb_row_t   row_solid;
   rgb_row_t   row_hscan;
   rgb_row_t   row_vscan;
   rgb_row_t   row_pulse;
   rgb_row_t   row_debugv;
   reg [3:0]   address_vscan;
   
   //---------------------------------------------------------
   //                   Main State Machine                  --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         mode_buf <= {4{1'b0}};
      end
      else begin
         mode_buf <= mode_in;
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         row <= {GL_RGB_ROW_W{1'b0}};
      end
      else if (mode_buf != mode_in) begin
         row <= {GL_RGB_ROW_W{1'b0}};
      end
      else begin
         case (mode_buf)
            MODE_OFF : begin
               row <= {GL_RGB_ROW_W{1'b0}};
            end
            
            MODE_SOLID : begin
               row <= row_solid;
            end
            
            MODE_SCAN_H : begin
               row <= row_hscan;
            end
            
            MODE_SCAN_V : begin
               row <= row_vscan;
            end
            
            MODE_PULSE : begin
               row <= row_pulse;
            end
            
            DEBUG_V : begin
               row <= row_debugv;
            end
            
         endcase
      end
   end
   
   //---------------------------------------------------------
   //                         Effects                       --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         row_solid <= {GL_RGB_ROW_W{1'b0}};
      end
      else begin
         row_solid.top.red     <= {GL_NUM_COL_PIXELS{colour_in[0]}};
         row_solid.bot.red     <= {GL_NUM_COL_PIXELS{colour_in[0]}};
         row_solid.top.green   <= {GL_NUM_COL_PIXELS{colour_in[1]}};
         row_solid.bot.green   <= {GL_NUM_COL_PIXELS{colour_in[1]}};
         row_solid.top.blue    <= {GL_NUM_COL_PIXELS{colour_in[2]}};
         row_solid.bot.blue    <= {GL_NUM_COL_PIXELS{colour_in[2]}};
      end
   end
   
   pattern_hscan #(
         .EFFECT_TIMER  ( EFFECT_TIMER ),
         .SIMULATION    ( SIMULATION ))
      hscan (
         .clk_in        ( clk_in ),
         .n_reset_in    ( n_reset_in ),
         .colour_in     ( colour_in ),
         .row_out       ( row_hscan ));
   
   pattern_vscan #(
         .EFFECT_TIMER  ( EFFECT_TIMER ))
      vscan (
         .clk_in           ( clk_in ),
         .n_reset_in       ( n_reset_in ),
         .colour_in        ( colour_in ),
         .row_out          ( row_vscan ),
         .row_address_out  ( address_vscan ));
   
   pattern_pulse #(
         .SYS_CLK_FREQ  ( SYS_CLK_FREQ ),
         .PWM_FREQ      ( PWM_FREQ ),
         .EFFECT_TIMER  ( EFFECT_TIMER ))
      pulse (
         .clk_in           ( clk_in ),
         .n_reset_in       ( n_reset_in ),
         .colour_in        ( colour_in ),
         .row_out          ( row_pulse ));
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         row_debugv <= {GL_RGB_ROW_W{1'b0}};
      end
      else begin
         row_debugv.top.red <= {1'b0, row_address[3:0]};
         row_debugv.bot.red <= {1'b1, row_address[3:0]};
      end
   end
   
   //---------------------------------------------------------
   //                   Output Control                      --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         row_valid <= 1'b0;
      end
      else begin
         if (mode_buf != mode_in) begin
            row_valid <= 1'b0;
         end
         else if (row_ready_in) begin
            row_valid <= 1'b1;
         end
         else begin
            row_valid <= 1'b0;
         end
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         row_address <= {4{1'b0}};
      end
      else begin
         if (mode_buf != mode_in) begin
            row_address <= {4{1'b0}};
         end
         else if (row_valid && !row_ready_in) begin
            row_address <= row_address + 1'b1;
         end
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         row_address_buf <= {4{1'b0}};
      end
      else begin
         if (mode_buf == MODE_SCAN_V) begin
            row_address_buf <= address_vscan;
         end
         else begin
            row_address_buf <= row_address;
         end
      end
   end
   
   assign row_valid_out = row_valid;
   assign row_out = row;
   assign row_address_out[3:0] = row_address_buf[3:0];
   
endmodule
