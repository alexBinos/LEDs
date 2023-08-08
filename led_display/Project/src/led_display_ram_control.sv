
import led_display_package::*;

module led_display_ram_control (
   input  wire          clk_in,
   input  wire          n_reset_in,
   
   output wire [12:0]   ram_address_out,
   input  wire [63:0]   ram_rdata_in,
   
   output rgb_row_t     row_out,
   output wire          row_valid_out,
   output wire [3:0]    row_address_out,
   input  wire          row_ready_in
);
   
   reg [12:0]  ram_addr_buf;
   reg [63:0]  ram_data_buf;
   
   rgb_row_t   row_buf;
   reg         row_valid_buf;
   reg [3:0]   row_addr_buf;
   
   
   reg [1:0]   count;
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         ram_addr_buf <= {13{1'b0}};
      end
      else begin
         if (count == 2'b11) begin
            ram_addr_buf <= ram_addr_buf + 1'b1;
         end
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         count <= 2'b00;
      end
      else begin
         if (row_ready_in) begin
            count <= count + 1'b1;
         end
         else begin
            count <= 2'b00;
         end
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         row_buf <= {GL_RGB_ROW_W{1'b0}};
         row_valid_buf <= 1'b0;
         row_addr_buf <= {4{1'b0}};
      end
      else begin
         if (count == 2'b11) begin
            row_buf.top.red <= ram_rdata_in;
            row_buf.bot.green <= ram_rdata_in;
            row_valid_buf <= 1'b1;
            row_addr_buf <= ram_addr_buf[3:0];
         end
         else begin
            row_valid_buf <= 1'b0;
         end
      end
   end
   
   assign ram_address_out   = ram_addr_buf[3:0];
   assign row_out           = row_buf;
   assign row_valid_out     = row_valid_buf;
   assign row_address_out   = row_addr_buf;
   
endmodule
