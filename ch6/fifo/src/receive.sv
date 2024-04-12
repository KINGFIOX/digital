module handshake_rclk (
    input rclk,
    input resetb_rclk,
    input t_rdy,
    input [31:0] t_data,
    output reg r_ack
);

  localparam IDLE_R = 1'b0, ASSERT_ACK = 1'b1;

  reg r_hndshk_state, r_hndshk_state_nxt;
  reg r_ack_nxt;
  reg [31:0] t_data_rclk, t_data_rclk_nxt;
  reg t_rdy_d1, t_rdy_rclk;

  /// 状态转移
  /// 我们之前都是三段式，但是书上的代码是两段式
  always_comb begin
    r_hndshk_state_nxt = r_hndshk_state;
    r_ack_nxt = 1'b0;
    t_data_rclk_nxt = t_data_rclk;

    case (r_hndshk_state)
      IDLE_R: begin
        if (t_rdy_rclk) begin
          r_hndshk_state_nxt = ASSERT_ACK;
          r_ack_nxt = 1'b1;
          t_data_rclk_nxt = t_data;
        end
      end
      ASSERT_ACK: begin
        if (!t_rdy_rclk) begin
          r_ack_nxt = 1'b0;
          r_hndshk_state_nxt = IDLE_R;
        end else begin
          r_ack_nxt = 1'b1;
        end
      end
      default: begin
      end
    endcase
  end

  always_ff @(posedge rclk or negedge resetb_rclk) begin
    if (!resetb_rclk) begin
      r_hndshk_state <= IDLE_R;
      r_ack <= 1'b0;
      t_data_rclk <= 'd0;
      t_rdy_d1 <= 1'b0;
      t_rdy_rclk <= 1'b0;
    end else begin
      r_hndshk_state <= r_hndshk_state_nxt;
      r_ack <= r_ack_nxt;
      t_data_rclk <= t_data_rclk_nxt;
      t_rdy_d1 <= t_rdy;  // t_rdy_d1 是 一级触发器延迟
      t_rdy_rclk <= t_rdy_d1;  // t_rdy_rclk 是 二级触发器延迟
    end
  end

endmodule
