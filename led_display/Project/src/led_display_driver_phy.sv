/*
 Display driver for LED matrix display
 
 State machine logic
 
 0. Wait for new pixel
 1. Buffer pixel
 2. Shift out a new pixel after the rising edge of bit clock
 3a. Increment total bit count
 3b. If total bit count exceeds number of row bits, reset and increment address
 3c. Assert done signal to trigger memory controller to send another pixel
 3d. Return to IDLE
 
 - Gate output clock with enable_in
 
 
*/

module led_display_driver_phy #(
   parameter integer WRITE_FREQ         = 1_000_000,     // Data clock frequency (1MHz)
   parameter integer SYS_CLK_FREQ       = 100_000_000)   // Board clock frequency (100MHz)
(
   // Module control
   input wire           clk_in,
   input wire           n_reset_in,
   input wire           enable_in,
   output wire          ready_out,
   
   // Pixels to write
   input wire [23:0]    pixel_top_in,
   input wire [23:0]    pixel_bot_in,
   
   // Display control
   output wire [2:0]    rgb_top_out,
   output wire [2:0]    rgb_bot_out,
   output wire          bit_clk_out
);
   
   //---------------------------------------------------------
   //             Local Parameters and Types                --
   //---------------------------------------------------------
   
   localparam integer BIT_CLK_COUNT = SYS_CLK_FREQ / (WRITE_FREQ * 2); // Half period count
   localparam integer BIT_CLK_COUNT_W = $clog2(BIT_CLK_COUNT + 1);
   
   typedef enum logic [3:0]{
      SS_IDLE,
      SS_WRITE,
      SS_DONE
   } state_t;
   
   state_t state;
   
   //---------------------------------------------------------
   //                Variables and Signals                  --
   //---------------------------------------------------------
   
   reg [(BIT_CLK_COUNT_W - 1):0] bclk_cntr;
   reg bclk;
   reg bclk_nsclr;
   reg [1:0] bclk_buf;
   reg s_ready;
   
   reg [4:0] pixel_bit_counter;
   
   reg [7:0] r_top_buf;
   reg [7:0] g_top_buf;
   reg [7:0] b_top_buf;
   
   reg [7:0] r_bot_buf;
   reg [7:0] g_bot_buf;
   reg [7:0] b_bot_buf;
   
   //---------------------------------------------------------
   //                   Main State Machine                  --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in, negedge n_reset_in) begin
      if (!n_reset_in) begin
         state <= SS_IDLE;
         bclk_nsclr <= 1'b1;
         pixel_bit_counter <= {5{1'b0}};
         s_ready <= 1'b1;
         r_top_buf <= 8'h00;
         g_top_buf <= 8'h00;
         b_top_buf <= 8'h00;
         r_bot_buf <= 8'h00;
         g_bot_buf <= 8'h00;
         b_bot_buf <= 8'h00;
      end
      else begin
         case (state)
            
            SS_IDLE : begin
               if (enable_in) begin
                  
                  r_top_buf[7:0] <= pixel_top_in[0+:8];
                  g_top_buf[7:0] <= pixel_top_in[8+:8];
                  b_top_buf[7:0] <= pixel_top_in[16+:8];
                  
                  r_bot_buf[7:0] <= pixel_bot_in[0+:8];
                  g_bot_buf[7:0] <= pixel_bot_in[8+:8];
                  b_bot_buf[7:0] <= pixel_bot_in[16+:8];
                  
                  s_ready <= 1'b0;
                  state <= SS_WRITE;
               end
               else begin
                  s_ready <= 1'b1;
                  bclk_nsclr <= 1'b0;
                  r_top_buf <= 8'h00;
                  g_top_buf <= 8'h00;
                  b_top_buf <= 8'h00;
                  r_bot_buf <= 8'h00;
                  g_bot_buf <= 8'h00;
                  b_bot_buf <= 8'h00;
                  
               end
            end
            
            SS_WRITE : begin
               bclk_nsclr <= 1'b1;
               
               if (pixel_bit_counter >= 5'd8) begin
                  state <= SS_DONE;
               end
               else if (bclk_buf == 2'b10) begin
                  // Shift data on falling edge
                  r_top_buf[7:0] <= {r_top_buf[6:0], 1'b0};
                  g_top_buf[7:0] <= {g_top_buf[6:0], 1'b0};
                  b_top_buf[7:0] <= {b_top_buf[6:0], 1'b0};
                  r_bot_buf[7:0] <= {r_bot_buf[6:0], 1'b0};
                  g_bot_buf[7:0] <= {g_bot_buf[6:0], 1'b0};
                  b_bot_buf[7:0] <= {b_bot_buf[6:0], 1'b0};
                  pixel_bit_counter <= pixel_bit_counter + 1'b1;
               end
               
            end
            
            SS_DONE : begin
               s_ready <= 1'b1;
               bclk_nsclr <= 1'b0;
               pixel_bit_counter <= {5{1'b0}};
               r_top_buf <= 8'h00;
               g_top_buf <= 8'h00;
               b_top_buf <= 8'h00;
               r_bot_buf <= 8'h00;
               g_bot_buf <= 8'h00;
               b_bot_buf <= 8'h00;
               
               state <= SS_IDLE;
               //if (!enable_in) begin
               //   state <= SS_IDLE;
               //end
            end
            
         endcase
      end
   end
   
   //---------------------------------------------------------
   //                   Clock Generation                    --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in, negedge n_reset_in) begin
      if (!n_reset_in) begin
         bclk_cntr <= {BIT_CLK_COUNT_W{1'b0}};
         bclk <= 1'b0;
         bclk_buf <= 2'b00;
      end
      else begin
         bclk_buf[1:0] <= {bclk_buf[0], bclk};
         
         if (!bclk_nsclr) begin
            bclk_cntr <= {BIT_CLK_COUNT_W{1'b0}};
            bclk <= 1'b0;
         end
         else if (bclk_cntr >= BIT_CLK_COUNT) begin
            bclk_cntr <= {BIT_CLK_COUNT_W{1'b0}};
            bclk <= ~bclk;
         end
         else begin
            bclk_cntr <= bclk_cntr + 1'b1;
         end
      end
   end
   
   //---------------------------------------------------------
   //                   Output Control                      --
   //---------------------------------------------------------
   
   
   assign rgb_top_out[0] = r_top_buf[7]; 
   assign rgb_top_out[1] = g_top_buf[7]; 
   assign rgb_top_out[2] = b_top_buf[7]; 
   
   assign rgb_bot_out[0] = r_bot_buf[7]; 
   assign rgb_bot_out[1] = g_bot_buf[7]; 
   assign rgb_bot_out[2] = b_bot_buf[7]; 
   
   assign bit_clk_out = bclk;
   assign ready_out = s_ready;
   
endmodule
