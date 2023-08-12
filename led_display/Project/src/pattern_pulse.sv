
import led_display_package::*;

module pattern_pulse #(
   parameter integer SYS_CLK_FREQ   = 100_000_000,
   parameter integer PWM_FREQ       = 20_000,
   parameter integer EFFECT_TIMER   = 100_000
)(
   input  wire          clk_in,
   input  wire          n_reset_in,
   
   input  wire [2:0]    colour_in,
   output rgb_row_t     row_out
);
   
   //---------------------------------------------------------
   //             Local Parameters and Types                --
   //---------------------------------------------------------
   
   localparam integer EFFECT_TIMER_W    = $clog2(EFFECT_TIMER + 1);
   localparam integer FADE_MAX          = 8'hFE;
   localparam integer FADE_MIN          = 8'h01;
   
   //---------------------------------------------------------
   //                Variables and Signals                  --
   //---------------------------------------------------------
   
   reg [(EFFECT_TIMER_W - 1):0]        timer;
   reg                                 update;
   reg                                 pulse_dir;
   reg [7:0]                           pulse_val;
   wire                                pwm_colour;
   
   //---------------------------------------------------------
   //                   Update Control                      --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         timer <= {EFFECT_TIMER_W{1'b0}};
      end
      else begin
         if (timer >= EFFECT_TIMER) begin
            timer <= {EFFECT_TIMER_W{1'b0}};
            update <= 1'b1;
         end
         else begin
            timer <= timer + 1'b1;
            update <= 1'b0;
         end
      end
   end
   
   //---------------------------------------------------------
   //                   Direction Control                   --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         pulse_dir <= 1'b1;
      end
      else begin
         if (update) begin
            if (pulse_val >= FADE_MAX) begin
               pulse_dir <= 1'b0;
            end
            else if (pulse_val <= FADE_MIN) begin
               pulse_dir <= 1'b1;
            end
         end
      end
   end
   
   //---------------------------------------------------------
   //                   Pulse Value Control                 --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         pulse_val <= {8{1'b0}};
      end
      else begin
         if (update) begin
            if (pulse_dir) begin
               pulse_val <= pulse_val + 1'b1;
            end
            else begin
               pulse_val <= pulse_val - 1'b1;
            end
         end
      end
   end
   
   //---------------------------------------------------------
   //                      PWM Control                      --
   //---------------------------------------------------------
   
   pwm_generator #(
         .SYS_CLK_FREQ     ( SYS_CLK_FREQ ),
         .PWM_FREQ         ( PWM_FREQ ),
         .BIT_W            ( 8 ))
      pwm (
         .clk_in           ( clk_in ),
         .n_reset_in       ( n_reset_in ),
         .colour_in        ( pulse_val ),
         .pwm_colour_out   ( pwm_colour ));
   
   assign row_out.top.red      = pwm_colour ? {GL_NUM_COL_PIXELS{colour_in[0]}} : {GL_NUM_COL_PIXELS{1'b0}};
   assign row_out.bot.red      = pwm_colour ? {GL_NUM_COL_PIXELS{colour_in[0]}} : {GL_NUM_COL_PIXELS{1'b0}};
   assign row_out.top.green    = pwm_colour ? {GL_NUM_COL_PIXELS{colour_in[1]}} : {GL_NUM_COL_PIXELS{1'b0}};
   assign row_out.bot.green    = pwm_colour ? {GL_NUM_COL_PIXELS{colour_in[1]}} : {GL_NUM_COL_PIXELS{1'b0}};
   assign row_out.top.blue     = pwm_colour ? {GL_NUM_COL_PIXELS{colour_in[2]}} : {GL_NUM_COL_PIXELS{1'b0}};
   assign row_out.bot.blue     = pwm_colour ? {GL_NUM_COL_PIXELS{colour_in[2]}} : {GL_NUM_COL_PIXELS{1'b0}};
   
endmodule
