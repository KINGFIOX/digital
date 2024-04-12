/// 如果晶体震荡为 200Hz, 也就是 US_COUNTER_MAX=199, 那么就能正确计时
module timertick_gen #(
    parameter US_COUNTER_MAX = 'd199
) (
    input clk_200,
    input resetb,
    output reg us_tick,
    output reg ms_tick,
    output reg sec_tick
);

  reg [7:0] us_counter;
  wire [7:0] us_counter_nxt = (us_counter == US_COUNTER_MAX) ? 'd0 : (us_counter + 1'b1);
  wire us_tick_nxt = (us_counter == US_COUNTER_MAX);

  reg [9:0] ms_counter, ms_counter_nxt;
  always_comb begin
    ms_counter_nxt = ms_counter;
    if (us_tick) begin
      if (ms_counter == 'd999) begin
        ms_counter_nxt = 'd0;
      end else begin
        ms_counter_nxt = ms_counter + 1'b1;
      end
    end
  end

  assign ms_tick_nxt = (ms_counter == 'd999);
  reg [9:0] sec_counter;
  wire [9:0] sec_counter_nxt = ms_tick ? ((sec_counter == 'd999) ? 'd0 : (sec_counter + 1'b1)) : sec_counter;

  assign sec_tick_nxt = (sec_counter == 'd999);

  always_ff @(posedge clk_200 or negedge resetb) begin
    if (!resetb) begin
      us_counter <= 'd0;
      ms_counter <= 'd0;
      sec_counter <= 'd0;
      us_tick <= 1'b0;
      ms_tick <= 1'b0;
      us_tick <= 1'b0;
    end else begin
      us_counter <= us_counter_nxt;
      ms_counter <= ms_counter_nxt;
      sec_counter <= sec_counter_nxt;
      us_tick <= us_tick_nxt;
      ms_tick <= ms_tick_nxt;
      us_tick <= us_tick_nxt;
    end
  end


endmodule
