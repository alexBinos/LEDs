
import led_display_package::*;

module led_display_ram_control (
   input  wire          clk_in,
   input  wire          n_reset_in,
   
   output wire [31:0]   ram_address_out,
   input  wire [31:0]   ram_rdata_in,
   
   output rgb_row_t     row_out,
   output wire          row_valid_out,
   output wire [3:0]    row_address_out,
   input  wire          row_ready_in
);
   
   //---------------------------------------------------------
   //             Local Parameters and Types                --
   //---------------------------------------------------------
   
   localparam integer RAM_ADDR_W        = 32;
   localparam integer LOAD_WORDS        = 12;
   localparam integer ADDR_WRAP         = (LOAD_WORDS * 16);
   localparam integer LOAD_WORDS_HALF   = (LOAD_WORDS / 2);
   localparam integer LOAD_W            = $clog2(LOAD_WORDS);
   
   typedef enum logic [3:0] {
      SS_IDLE,
      SS_WAIT,
      SS_LOAD,
      SS_WAIT2,
      SS_DONE
   } state_t;
   
   //---------------------------------------------------------
   //                Variables and Signals                  --
   //---------------------------------------------------------
   
   state_t state;
   
   reg [(RAM_ADDR_W - 1):0]   ram_addr_buf;
   reg [31:0]                 ram_data_buf;
   
   rgb_row_t   row_buf;
   reg         row_valid_buf;
   reg [3:0]   row_addr_buf;
   
   reg [3:0]   count;
   reg [(LOAD_W - 1):0] load_count;
   
   //---------------------------------------------------------
   //                   Main State Machine                  --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         state <= SS_IDLE;
      end
      else begin
         case (state)
            SS_IDLE : begin
               if (row_ready_in && !row_valid_buf) begin
                  state <= SS_WAIT;
               end
            end
            
            SS_WAIT : begin
               if (count == 3'b001) begin
                  state <= SS_LOAD;
               end
            end
            
            SS_LOAD : begin
               if (load_count >= (LOAD_WORDS - 1)) begin
                  state <= SS_WAIT2;
               end
            end
            
            SS_WAIT2 : begin
               if (count == 3'b001) begin
                  state <= SS_DONE;
               end
            end
            
            SS_DONE : begin
               state <= SS_IDLE;
            end
         endcase
      end
   end
   
   //---------------------------------------------------------
   //                      Buffering                        --
   //---------------------------------------------------------
   
   // RAM read delay counter
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         count <= {3{1'b0}};
      end
      else begin
         if ((state == SS_WAIT) || (state == SS_WAIT2)) begin
            count <= count + 1'b1;
         end
         else begin
            count <= {3{1'b0}};
         end
      end
   end
   
   // RAM word address counter
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         ram_addr_buf <= {RAM_ADDR_W{1'b0}};
      end
      else begin
         if ((state == SS_WAIT) || (state == SS_LOAD)) begin
            ram_addr_buf <= ram_addr_buf + 1'b1;
         end
         else if (ram_addr_buf >= ADDR_WRAP) begin
            ram_addr_buf <= {RAM_ADDR_W{1'b0}};
         end
      end
   end
   
   // Load word counter
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         load_count <= {LOAD_W{1'b0}};
      end
      else begin
         if ((state == SS_WAIT) || (state == SS_LOAD)) begin
            load_count <= load_count + 1'b1;
         end
         else begin
            load_count <= {LOAD_W{1'b0}};
         end
      end
   end
   
   // Row buffer shift register
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         row_buf <= {GL_RGB_ROW_W{1'b0}};
      end
      else begin
         if ((state == SS_LOAD) || (state == SS_WAIT2)) begin
            row_buf[(GL_RGB_ROW_W - 1):0] <= {row_buf[(GL_RGB_ROW_W - 32):0], ram_rdata_in[31:0]};
         end
      end
   end
   
   // Row valid control
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         row_valid_buf <= 1'b0;
      end
      else begin
         if (state == SS_DONE) begin
            row_valid_buf <= 1'b1;
         end
         else begin
            row_valid_buf <= 1'b0;
         end
      end
   end
   
   // Row address counter
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         row_addr_buf <= {4{1'b0}};
      end
      else begin
         if (row_valid_buf) begin
            row_addr_buf <= row_addr_buf + 1'b1;
         end
      end
   end
   
   assign ram_address_out   = ram_addr_buf;
   assign row_out           = row_buf;
   assign row_valid_out     = row_valid_buf;
   assign row_address_out   = row_addr_buf;
   
endmodule
