module pulse_synchronizer (
    input clksrc,
    input resetb_clksrc,
    input clkdest,
    input resetb_clkdest,
    input pulse_src,
    output wire pulse_dest
);

  /// 依赖关系: ack_edge -> ack -> ack_pre -> stretched_dest -> stretched_sync1 -> stretched -> pulse_src

  /// 初始状态: ack_edge=0 , pluse_src=1 , stretched=0 -> stretched_nxt=1
  /// clksrc pos -> stretched=1 ->(late 1destclk) streched_sync1=1 ->(late 1destclk) sync1=1 ->(late 1destclk) dest_d1=1
  /// 

  // stretched .adj 拉伸的
  reg sig_stretched;
  reg sig_stretched_ack_pre, sig_stretched_ack;
  reg  sig_stretched_ack_d1;

  /// ack_d1 比 ack 慢一个 时钟周期，可以检测 ack 的上升沿
  wire sig_stretched_ack_edge = sig_stretched_ack & ~sig_stretched_ack_d1;
  wire sig_stretched_nxt = sig_stretched_ack_edge ? 1'b0 : (pulse_src ? 1'b1 : sig_stretched);

  /// sig_stretched_nxt 是对 src 的同步
  always_ff @(posedge clksrc or negedge resetb_clksrc) begin
    if (!resetb_clkdest  /* verilator lint_off SYNCASYNCNET */) begin
      sig_stretched <= 1'b0;
    end else begin
      sig_stretched <= sig_stretched_nxt;
    end
  end

  /// 这一块是对 dest 的同步
  reg sig_stretched_sync1, sig_stretched_dest;
  reg sig_stretched_dest_d1;
  always_ff @(posedge clkdest or negedge resetb_clkdest) begin
    if (!resetb_clkdest  /* verilator lint_off SYNCASYNCNET */) begin
      sig_stretched_sync1 <= 1'b0;
      sig_stretched_dest <= 1'b0;
      sig_stretched_dest_d1 <= 1'b0;
    end else begin
      sig_stretched_sync1 <= sig_stretched;
      sig_stretched_dest <= sig_stretched_sync1;
      sig_stretched_dest_d1 <= sig_stretched_dest;
    end
  end

  always_ff @(posedge clksrc or negedge resetb_clksrc) begin
    if (!resetb_clksrc) begin
      sig_stretched_ack_pre <= 1'b0;
      sig_stretched_ack <= 1'b0;
      sig_stretched_ack_d1 <= 1'b0;
    end else begin
      sig_stretched_ack_pre <= sig_stretched_dest;
      sig_stretched_ack <= sig_stretched_ack_pre;
      sig_stretched_ack_d1 <= sig_stretched_ack;
    end
  end

  assign pulse_dest = sig_stretched_dest & !sig_stretched_dest_d1;

endmodule
