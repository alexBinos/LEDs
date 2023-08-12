
import led_display_package::*;

module pattern_hscan #(
   parameter integer EFFECT_TIMER   = 100_000,
   parameter integer SIMULATION     = 0
)(
   input  wire          clk_in,
   input  wire          n_reset_in,
   
   input  wire [2:0]    colour_in,
   output rgb_row_t     row_out
);
   
   //---------------------------------------------------------
   //             Local Parameters and Types                --
   //---------------------------------------------------------
   
   localparam integer EFFECT_TIMER_W                = $clog2(EFFECT_TIMER + 1);
   localparam [(GL_NUM_COL_PIXELS - 1):0] SCAN_MAX  = (1 << (GL_NUM_COL_PIXELS - 2));
   localparam [(GL_NUM_COL_PIXELS - 1):0] SCAN_MIN  = 2;
   
   //---------------------------------------------------------
   //                Variables and Signals                  --
   //---------------------------------------------------------
   
   reg [(EFFECT_TIMER_W - 1):0]        scan_timer;
   reg                                 scan_update;
   reg                                 scan_dir;
   reg [(GL_NUM_COL_PIXELS - 1):0]     scan_buf;
   
   //---------------------------------------------------------
   //                Scan Update Control                    --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         scan_timer <= {EFFECT_TIMER_W{1'b0}};
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
   
   //---------------------------------------------------------
   //                Scan Direction Control                 --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         scan_dir <= 1'b1;
      end
      else begin
         if (scan_update) begin
            if (scan_buf & SCAN_MAX) begin
               scan_dir <= 1'b0;
            end
            else if (scan_buf & SCAN_MIN) begin
               scan_dir <= 1'b1;
            end
         end
      end
   end
   
   //---------------------------------------------------------
   //                Scan Shift Register Control            --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         scan_buf <= {{(GL_NUM_COL_PIXELS - 1){1'b0}}, 1'b1};
      end
      else begin
         if (scan_update) begin
            if (scan_dir) begin
               scan_buf <= scan_buf << 1'b1;
            end
            else begin
               scan_buf <= scan_buf >> 1'b1;
            end
         end
      end
   end
   
   assign row_out.top.red      = colour_in[0] ? scan_buf[(GL_NUM_COL_PIXELS - 1):0] : {GL_NUM_COL_PIXELS{1'b0}};
   assign row_out.bot.red      = colour_in[0] ? scan_buf[(GL_NUM_COL_PIXELS - 1):0] : {GL_NUM_COL_PIXELS{1'b0}};
   assign row_out.top.green    = colour_in[1] ? scan_buf[(GL_NUM_COL_PIXELS - 1):0] : {GL_NUM_COL_PIXELS{1'b0}};
   assign row_out.bot.green    = colour_in[1] ? scan_buf[(GL_NUM_COL_PIXELS - 1):0] : {GL_NUM_COL_PIXELS{1'b0}};
   assign row_out.top.blue     = colour_in[2] ? scan_buf[(GL_NUM_COL_PIXELS - 1):0] : {GL_NUM_COL_PIXELS{1'b0}};
   assign row_out.bot.blue     = colour_in[2] ? scan_buf[(GL_NUM_COL_PIXELS - 1):0] : {GL_NUM_COL_PIXELS{1'b0}};
   
endmodule
