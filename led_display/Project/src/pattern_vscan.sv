
import led_display_package::*;

module pattern_vscan #(
   parameter integer EFFECT_TIMER   = 100_000
)(
   input  wire          clk_in,
   input  wire          n_reset_in,
   
   input  wire [2:0]    colour_in,
   output rgb_row_t     row_out,
   output wire [3:0]    row_address_out
);
   
   //---------------------------------------------------------
   //             Local Parameters and Types                --
   //---------------------------------------------------------
   
   localparam integer EFFECT_TIMER_W    = $clog2(EFFECT_TIMER + 1);
   localparam integer SCAN_MAX          = (GL_NUM_ROW_PIXELS - 2);
   localparam integer SCAN_MIN          = 1;
   
   //---------------------------------------------------------
   //                Variables and Signals                  --
   //---------------------------------------------------------
   
   reg [(EFFECT_TIMER_W - 1):0]        scan_timer;
   reg                                 scan_update;
   reg                                 scan_dir;
   reg [4:0]                           scan_addr;
   reg [3:0]                           address_counter;
   reg [3:0]                           row_address_buf;
   rgb_row_t                           row_buf;
   
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
            if (scan_addr >= SCAN_MAX) begin
               scan_dir <= 1'b0;
            end
            else if (scan_addr <= SCAN_MIN) begin
               scan_dir <= 1'b1;
            end
         end
      end
   end
   
   //---------------------------------------------------------
   //                   Scan Address Control                --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         address_counter <= {4{1'b0}};
      end
      else begin
         address_counter <= address_counter + 1'b1;
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         scan_addr <= {5{1'b0}};
      end
      else begin
         if (scan_update) begin
            if (scan_dir) begin
               scan_addr <= scan_addr + 1'b1;
            end
            else begin
               scan_addr <= scan_addr - 1'b1;
            end
         end
      end
   end
   
   //---------------------------------------------------------
   //             Row Select and Output Buffer Stage        --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         row_buf <= {GL_RGB_ROW_W{1'b0}};
      end
      else begin
         if (scan_addr[4]) begin
            row_buf.top <= {GL_RGB_COL_W{1'b0}};
            if (address_counter[3:0] == scan_addr[3:0]) begin
               row_buf.bot.red    <= {GL_NUM_COL_PIXELS{colour_in[0]}};
               row_buf.bot.green  <= {GL_NUM_COL_PIXELS{colour_in[1]}};
               row_buf.bot.blue   <= {GL_NUM_COL_PIXELS{colour_in[2]}};
            end
            else begin
               row_buf.bot <= {GL_RGB_COL_W{1'b0}};
            end
         end
         else begin
            row_buf.bot <= {GL_RGB_COL_W{1'b0}};
            if (address_counter[3:0] == scan_addr[3:0]) begin
               row_buf.top.red    <= {GL_NUM_COL_PIXELS{colour_in[0]}};
               row_buf.top.green  <= {GL_NUM_COL_PIXELS{colour_in[1]}};
               row_buf.top.blue   <= {GL_NUM_COL_PIXELS{colour_in[2]}};
            end
            else begin
               row_buf.top <= {GL_RGB_COL_W{1'b0}};
            end
         end
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         row_address_buf <= {4{1'b0}};
      end
      else begin
         row_address_buf <= address_counter;
      end
   end
   
   assign row_out = row_buf;
   assign row_address_out = row_address_buf;
   
endmodule
