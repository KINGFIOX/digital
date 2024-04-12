# README

这个仓库学习 《verilog 高级数字系统 设计技术与实例分析》

- 环境: verilator + makefile + dwfv(看波形的)
- 系统: opensuse + mac + vscode

- ch5: 数字电路设计 初级篇
  - counter: lfsr_counter + versat_updown_counter
- ch6:
  - RTL(register transfer level, 寄存器传输级描述, 一般都是这种)-PCIe 扰码器(scrambler)
  -

## 触发器延迟

```verilog
  always_ff @(posedge tclk or negedge resetb_tclk) begin
    if (!resetb_tclk) begin
      r_ack_d1 <= 1'b0;
      r_ack_tclk <= 1'b0;
    end else begin
      r_ack_d1 <= r_ack;
      r_ack_tclk <= r_ack_d1;
    end
  end
```

比方说这段代码，这个 r_ack_d1 和 r_ack_tclk
通常是同来延时的（两级触发器），有助于防止亚状态的发生。
