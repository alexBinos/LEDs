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
   localparam integer EFFECT_TIMER_W    = $clog2(EFFECT_TIMER + 1);
   localparam [(GL_NUM_COL_PIXELS - 1):0] SCAN_MAX = (1 << (GL_NUM_COL_PIXELS - 2));
   localparam [(GL_NUM_COL_PIXELS - 1):0] SCAN_MIN = 2;
   localparam integer PWM_FREQ          = SIMULATION ? 100_000 : 20_000;
   
   //---------------------------------------------------------
   //                Variables and Signals                  --
   //---------------------------------------------------------
   
   rgb_row_t   row;
   rgb_row_t   row_buf;
   reg         row_valid;
   reg [3:0]   row_address;
   reg [3:0]   row_address_buf;
   
   reg [3:0] mode_buf;
   
   reg                                 hscan_dir;
   reg [(GL_NUM_COL_PIXELS - 1):0]     hscan_buf;
   reg [(EFFECT_TIMER_W - 1):0]        scan_timer;
   reg                                 scan_update;
   
   reg                                 vscan_dir;
   reg [(GL_NUM_ROW_PIXELS_W - 1):0]   vscan_address;
   
   reg                                 fade_dir;
   reg [7:0]                           fade_val;
   wire                                pwm_colour;
   
   
   //---------------------------------------------------------
   //                   Main State Machine                  --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         row <= {GL_RGB_ROW_W{1'b0}};
      end
      if (mode_buf != mode_in) begin
         row <= {GL_RGB_ROW_W{1'b0}};
      end
      else begin
         case (mode_buf)
            MODE_OFF : begin
               row <= {GL_RGB_ROW_W{1'b0}};
            end
            
            MODE_SOLID : begin
               row.top.red     <= {GL_NUM_COL_PIXELS{colour_in[0]}};
               row.bot.red     <= {GL_NUM_COL_PIXELS{colour_in[0]}};
               row.top.green   <= {GL_NUM_COL_PIXELS{colour_in[1]}};
               row.bot.green   <= {GL_NUM_COL_PIXELS{colour_in[1]}};
               row.top.blue    <= {GL_NUM_COL_PIXELS{colour_in[2]}};
               row.bot.blue    <= {GL_NUM_COL_PIXELS{colour_in[2]}};
            end
            
            MODE_SCAN_H : begin
               row.top.red     <= colour_in[0] ? hscan_buf[(GL_NUM_COL_PIXELS - 1):0] : {GL_NUM_COL_PIXELS{1'b0}};
               row.bot.red     <= colour_in[0] ? hscan_buf[(GL_NUM_COL_PIXELS - 1):0] : {GL_NUM_COL_PIXELS{1'b0}};
               row.top.green   <= colour_in[1] ? hscan_buf[(GL_NUM_COL_PIXELS - 1):0] : {GL_NUM_COL_PIXELS{1'b0}};
               row.bot.green   <= colour_in[1] ? hscan_buf[(GL_NUM_COL_PIXELS - 1):0] : {GL_NUM_COL_PIXELS{1'b0}};
               row.top.blue    <= colour_in[2] ? hscan_buf[(GL_NUM_COL_PIXELS - 1):0] : {GL_NUM_COL_PIXELS{1'b0}};
               row.bot.blue    <= colour_in[2] ? hscan_buf[(GL_NUM_COL_PIXELS - 1):0] : {GL_NUM_COL_PIXELS{1'b0}};
            end
            
            MODE_SCAN_V : begin
               if (vscan_address[4]) begin
                  row.top <= {GL_RGB_COL_W{1'b0}};
                  if (row_address[3:0] == vscan_address[3:0]) begin
                     row.bot.red     <= {GL_NUM_COL_PIXELS{colour_in[0]}};
                     row.bot.green   <= {GL_NUM_COL_PIXELS{colour_in[1]}};
                     row.bot.blue    <= {GL_NUM_COL_PIXELS{colour_in[2]}};
                  end
                  else begin
                     row.bot <= {GL_RGB_COL_W{1'b0}};
                  end
               end
               else begin
                  row.bot <= {GL_RGB_COL_W{1'b0}};
                  if (row_address[3:0] == vscan_address[3:0]) begin
                     row.top.red     <= {GL_NUM_COL_PIXELS{colour_in[0]}};
                     row.top.green   <= {GL_NUM_COL_PIXELS{colour_in[1]}};
                     row.top.blue    <= {GL_NUM_COL_PIXELS{colour_in[2]}};
                  end
                  else begin
                     row.top <= {GL_RGB_COL_W{1'b0}};
                  end
               end
            end
            
            MODE_PULSE : begin
               row.top.red     <= pwm_colour ? {GL_NUM_COL_PIXELS{colour_in[0]}} : {GL_NUM_COL_PIXELS{1'b0}};
               row.bot.red     <= pwm_colour ? {GL_NUM_COL_PIXELS{colour_in[0]}} : {GL_NUM_COL_PIXELS{1'b0}};
               row.top.green   <= pwm_colour ? {GL_NUM_COL_PIXELS{colour_in[1]}} : {GL_NUM_COL_PIXELS{1'b0}};
               row.bot.green   <= pwm_colour ? {GL_NUM_COL_PIXELS{colour_in[1]}} : {GL_NUM_COL_PIXELS{1'b0}};
               row.top.blue    <= pwm_colour ? {GL_NUM_COL_PIXELS{colour_in[2]}} : {GL_NUM_COL_PIXELS{1'b0}};
               row.bot.blue    <= pwm_colour ? {GL_NUM_COL_PIXELS{colour_in[2]}} : {GL_NUM_COL_PIXELS{1'b0}};
            end
            
            DEBUG_V : begin
               row.top.red <= {1'b0, row_address[3:0]};
               row.bot.red <= {1'b1, row_address[3:0]};
            end
            
         endcase
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         mode_buf <= {4{1'b0}};
      end
      else begin
         mode_buf <= mode_in;
      end
   end
   
   //---------------------------------------------------------
   //                         Effects                       --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         scan_timer <= {EFFECT_TIMER_W{1'b0}};
         scan_update <= 1'b0;
      end
      else begin
         if (scan_timer >= EFFECT_TIMER) begin
            scan_timer <= {EFFECT_TIMER_W{1'b0}};
            scan_update <= 1'b1;
         end
         else begin
            scan_timer <= scan_timer + 1'b1;
            scan_update <= 1'b0;
         end
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         hscan_buf <= {{(GL_NUM_COL_PIXELS - 1){1'b0}}, 1'b1};
         hscan_dir = 1'b1;
      end
      else begin
         if (mode_buf == MODE_SCAN_H) begin
            if (scan_update) begin
               if (hscan_dir) begin
                  hscan_buf <= hscan_buf << 1'b1;
                  if (hscan_buf & SCAN_MAX) begin
                     hscan_dir <= 1'b0;
                  end
               end
               else begin
                  hscan_buf <= hscan_buf >> 1'b1;
                  if (hscan_buf & SCAN_MIN) begin
                     hscan_dir <= 1'b1;
                  end
               end
            end
         end
         else begin
            hscan_buf <= {{(GL_NUM_COL_PIXELS - 1){1'b0}}, 1'b1};
         end
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         vscan_address <= {GL_NUM_ROW_PIXELS{1'b0}};
         vscan_dir <= 1'b1;
      end
      else begin
         if (mode_buf == MODE_SCAN_V) begin
            if (scan_update) begin
               if (vscan_dir) begin
                  vscan_address <= vscan_address + 1'b1;
                  if (vscan_address == (GL_NUM_ROW_PIXELS - 2)) begin
                     vscan_dir <= 1'b0;
                  end
               end
               else begin
                  vscan_address <= vscan_address - 1'b1;
                  if (vscan_address == 1) begin
                     vscan_dir <= 1'b1;
                  end
               end
            end
         end
      end
   end
   
   //---------------------------------------------------------
   //                   PWM Control                         --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         fade_val <= {8{1'b0}};
         fade_dir <= 1'b1;
      end
      else begin
         if (mode_buf == MODE_PULSE) begin
            if (scan_update) begin
               if (fade_dir) begin
                  fade_val <= fade_val + 1'b1;
                  if (fade_val >= 8'hFE) begin
                     fade_dir <= 1'b0;
                  end
               end
               else begin
                  fade_val <= fade_val - 1'b1;
                  if (fade_val <= 8'h01) begin
                     fade_dir <= 1'b1;
                  end
               end
            end
         end
         else begin
            fade_val <= {8{1'b0}};
         end
      end
   end
   
   pwm_generator #(
         .SYS_CLK_FREQ     ( SYS_CLK_FREQ ),
         .PWM_FREQ         ( PWM_FREQ ),
         .BIT_W            ( 8 ))
      pwm_gen (
         .clk_in           ( clk_in ),
         .n_reset_in       ( n_reset_in ),
         .colour_in        ( fade_val ),
         .pwm_colour_out   ( pwm_colour ));
   
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
         row_address_buf <= row_address;
      end
   end
   
   assign row_valid_out = row_valid;
   assign row_out = row;
   assign row_address_out = row_address;
   
endmodule
