module versat_updown_counter (
    input clk,
    input resetb,
    // 允许预设值
    input new_cntr_preset,
    input [7:0] new_cntr_preset_value,
    input enable_cnt_up,  // 向上计数
    input enable_cnt_dn,  // 向下计数
    input pause_counting,  // 暂停计数的信号
    output reg ctr_expired  // 计数完毕，期望
);

  reg [7:0] count255, count255_nxt;  // 当前计数值, 下一个周期的计数值
  reg [7:0] cnt_preset_stored;  // 存储预设值
  wire [7:0] cnt_preset_stored_nxt;  // 存储下一个周期的预设值
  wire ctr_expired_nxt;

  /// 用于边缘检测, 有一个清空寄存器的逻辑
  reg enable_cnt_up_d1, enable_cnt_dn_d1;  // 延迟，用于边缘检测
  wire enable_cnt_up_risedge = enable_cnt_up & ~enable_cnt_up_d1;
  wire enable_cnt_dn_risedge = enable_cnt_dn & ~enable_cnt_dn_d1;
  always_ff @(posedge clk or negedge resetb) begin
    if (!resetb) begin
      enable_cnt_up_d1 <= 1'b0;
      enable_cnt_dn_d1 <= 1'b0;
    end else begin
      enable_cnt_up_d1 <= enable_cnt_up;
      enable_cnt_dn_d1 <= enable_cnt_dn;
    end
  end

  assign cnt_preset_stored_nxt = new_cntr_preset ? new_cntr_preset_value : cnt_preset_stored;
  assign ctr_expired_nxt = enable_cnt_up ? (count255 == cnt_preset_stored) :
  (enable_cnt_dn ? (count255_nxt == 'd0) : 1'b0);

  always_comb begin
    count255_nxt = count255;
    if (enable_cnt_dn_risedge) begin
      count255_nxt = cnt_preset_stored;  // 开始计数啦 --> 设置 count255_nxt
    end else if (enable_cnt_up_risedge) begin
      count255_nxt = 'd0;
    end else if (pause_counting) begin
      count255_nxt = count255;
    end else if (enable_cnt_dn && ctr_expired) begin
      count255_nxt = cnt_preset_stored;
    end else if (enable_cnt_dn) begin
      count255_nxt = count255 - 1'b1;
    end else if (enable_cnt_up && ctr_expired) begin
      count255_nxt = 'd0;
    end else if (enable_cnt_up) begin
      count255_nxt = count255 + 1'b1;
    end
  end

  always_ff @(posedge clk or negedge resetb) begin
    if (!resetb) begin
      count255 <= 'd0;
      cnt_preset_stored <= 'd0;
      ctr_expired <= 1'b0;
    end else begin
      count255 <= count255_nxt;
      cnt_preset_stored <= cnt_preset_stored_nxt;
      ctr_expired <= ctr_expired_nxt;
    end
  end


endmodule
