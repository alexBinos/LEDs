

module pwm_generator #(
   parameter integer SYS_CLK_FREQ       = 100_000_000,   // System clock frequency 100MHz
   parameter integer PWM_FREQ           = 20_480,        // PWM frequency 20kHz
   parameter integer BIT_W              = 8              // Colour width 8 bits
)(
   input  wire                   clk_in,
   input  wire                   n_reset_in,
   input  wire [(BIT_W - 1):0]   colour_in,
   output wire                   pwm_colour_out
);
   
   //---------------------------------------------------------
   //             Local Parameters and Types                --
   //---------------------------------------------------------
   
   localparam integer PWM_FREQ_W = $clog2(PWM_FREQ + 1);
   localparam integer BITS = 2 ** BIT_W;
   localparam integer UNIT_COUNTS = (SYS_CLK_FREQ / (PWM_FREQ * BITS));
   localparam integer UNIT_COUNT_W = $clog2(UNIT_COUNTS + 1);
   
   //---------------------------------------------------------
   //                Variables and Signals                  --
   //---------------------------------------------------------
   
   reg [(UNIT_COUNT_W - 1):0]    unit_counter;
   reg [(BIT_W - 1):0]           compare_reg;
   reg [(BIT_W - 1):0]           colour_buf;
   reg                           pwm_colour;
   
   //---------------------------------------------------------
   //                         Main                          --
   //---------------------------------------------------------
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         colour_buf <= {BIT_W{1'b0}};
      end
      else begin
         colour_buf <= colour_in;
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         unit_counter <= {UNIT_COUNT_W{1'b0}};
         compare_reg <= {BIT_W{1'b0}};
      end
      else begin
         if (unit_counter >= UNIT_COUNTS) begin
            compare_reg <= compare_reg + 1'b1;
            unit_counter <= {UNIT_COUNT_W{1'b0}};
         end
         else begin
            unit_counter <= unit_counter + 1'b1;
         end
      end
   end
   
   always_ff @(posedge clk_in) begin
      if (!n_reset_in) begin
         pwm_colour <= 1'b0;
      end
      else begin
         if (colour_buf == {BIT_W{1'b0}}) begin
            pwm_colour <= 1'b0;
         end
         else if (colour_buf == {BIT_W{1'b1}}) begin
            pwm_colour <= 1'b1;
         end
         else begin
            pwm_colour <= (colour_buf >= compare_reg);
         end
      end
   end
   
   assign pwm_colour_out = pwm_colour;
   
endmodule
