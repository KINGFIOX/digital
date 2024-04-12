/// 线性反馈移位寄存器
/// 可以用来搞: 伪随机序列

module lfsr_counter (
    input clk,
    input resetb,
    input new_cntr_preset,
    input [3:0] seed,
    output wire ctr_expired
);

  reg [3:0] lfsr_cnt, lfsr_cnt_nxt;
  wire [3:0] lfsr_cnt_xor = {lfsr_cnt[0], lfsr_cnt[3] ^ lfsr_cnt[0], lfsr_cnt[2], lfsr_cnt[1]};

  always_comb begin
    if (new_cntr_preset) begin
      lfsr_cnt_nxt = seed;
    end else begin
      lfsr_cnt_nxt = lfsr_cnt_xor;
    end
  end

  always_ff @(posedge clk or negedge resetb) begin
    if (!resetb) begin
      lfsr_cnt <= 4'b1111;
    end else begin
      lfsr_cnt <= lfsr_cnt_nxt;
    end
  end

  assign ctr_expired = (lfsr_cnt == 4'b0111);


endmodule
