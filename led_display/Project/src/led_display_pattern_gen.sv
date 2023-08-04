

module led_display_pattern_gen #(
   parameter integer SYS_CLK_FREQ = 100_000_000
)(
   input  wire       clk_in,
   input  wire       n_reset_in,
   
   input  wire [3:0] mode_in,
   
   output rgb_row_t  row_out,
   output wire       row_valid_out,
   input  wire       row_ready_in
);
   
   
   localparam integer MODE_OFF          = 0;
   localparam integer MODE_SOLID_RED    = 1;
   localparam integer MODE_SOLID_GREEN  = 2;
   localparam integer MODE_SOLID_BLUE   = 3;
   localparam integer MODE_MIX_RG       = 4;
   localparam integer MODE_MIX_GB       = 5;
   localparam integer MODE_MIX_RB       = 6;
   
   rgb_row_t   row;
   reg         row_valid;
   
   reg [3:0] mode_buf;
   
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
      if (mode_buf != mode_in) begin
         row <= {GL_RGB_ROW_W{1'b0}};
      end
      else begin
         case (mode_in)
            MODE_OFF : begin
               row <= {GL_RGB_ROW_W{1'b0}};
            end
            
            MODE_SOLID_RED : begin
               row.top.red <= {GL_NUM_COL_PIXELS{1'b1}};
               row.bot.red <= {GL_NUM_COL_PIXELS{1'b1}};
            end
            
            MODE_SOLID_GREEN : begin
               row.top.green <= {GL_NUM_COL_PIXELS{1'b1}};
               row.bot.green <= {GL_NUM_COL_PIXELS{1'b1}};
            end
            
            MODE_SOLID_BLUE : begin
               row.top.blue <= {GL_NUM_COL_PIXELS{1'b1}};
               row.bot.blue <= {GL_NUM_COL_PIXELS{1'b1}};
            end
            
            MODE_MIX_RG : begin
               row.top.red <= {GL_NUM_COL_PIXELS{1'b1}};
               row.bot.red <= {GL_NUM_COL_PIXELS{1'b1}};
               row.top.green <= {GL_NUM_COL_PIXELS{1'b1}};
               row.bot.green <= {GL_NUM_COL_PIXELS{1'b1}};
            end
            
            MODE_MIX_GB : begin
               row.top.green <= {GL_NUM_COL_PIXELS{1'b1}};
               row.bot.green <= {GL_NUM_COL_PIXELS{1'b1}};
               row.top.blue <= {GL_NUM_COL_PIXELS{1'b1}};
               row.bot.blue <= {GL_NUM_COL_PIXELS{1'b1}};
            end
            
            MODE_MIX_RB : begin
               row.top.red <= {GL_NUM_COL_PIXELS{1'b1}};
               row.bot.red <= {GL_NUM_COL_PIXELS{1'b1}};
               row.top.blue <= {GL_NUM_COL_PIXELS{1'b1}};
               row.bot.blue <= {GL_NUM_COL_PIXELS{1'b1}};
            end
            
         endcase
      end
   end
   
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
   
   assign row_valid_out = row_valid;
   assign row_out = row;
   
endmodule
