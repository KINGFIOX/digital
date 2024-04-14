module BoothMul #(
    parameter WIDTH = 8,
    parameter log2WIDTH = $clog2(WIDTH)
) (
    input clk,
    input rst,
    input start,
    input signed [WIDTH-1:0] x,
    input signed [WIDTH-1:0] y,
    output reg signed [WIDTH+WIDTH-1:0] z,
    output valid,
    output reg signed [WIDTH-1:0] _x,
    output reg signed [WIDTH-1:0] _y
);

  localparam IDLE = 3'b001;
  localparam CACULATE = 3'b010;
  localparam FINISH = 3'b100;

  wire rst_n = ~rst;

  /// state 有三个状态，one-hot 状态编码
  reg [2:0] state;
  reg [2:0] next_state;

  reg [1:0] q_reg;  //右移最后两位寄存

  reg [log2WIDTH:0] cnt;  //右移次数计数信号


  /// 防止中间变卦
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      _x <= 0;
      _y <= 0;
    end else begin
      case (state)
        IDLE: begin
          _x <= x;
          _y <= y;
        end
        default: begin
          _x <= _x;
          _y <= _y;
        end
      endcase
    end
  end

  /// 状态迁移
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  /// 状态转移表
  always_comb begin
    next_state = state;
    case (state)
      IDLE: begin
        if (start) begin
          next_state = CACULATE;
        end else begin
          next_state = IDLE;
        end
      end
      CACULATE: begin
        if (cnt == WIDTH - 1) begin
          next_state = FINISH;
        end else begin
          next_state = CACULATE;
        end
      end
      FINISH: begin
        next_state = IDLE;
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end

  /// 输出方程
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt <= 0;
      q_reg <= 0;
      z <= 0;
    end else begin
      case (state)
        IDLE: begin
          cnt <= 0;
          q_reg <= {y[0], 1'b0};
          z <= {{WIDTH{1'b0}}, y};
        end
        CACULATE: begin
          cnt   <= cnt + 1;
          q_reg <= {_y[cnt[log2WIDTH-1:0]+1], _y[cnt[log2WIDTH-1:0]]};
          case (q_reg)
            2'b00, 2'b11: begin
              z <= $signed(z) >>> 1;
            end
            2'b10: begin
              z <= $signed({z[WIDTH+WIDTH-1:WIDTH] - _x, z[WIDTH-1:0]}) >>> 1;
            end
            2'b01: begin
              z <= $signed({z[WIDTH+WIDTH-1:WIDTH] + _x, z[WIDTH-1:0]}) >>> 1;
            end
          endcase
        end
        FINISH: begin
          cnt <= 0;
          q_reg <= 0;
          z <= z;
        end
        default: begin
          cnt <= 0;
          q_reg <= {y[0], 1'b0};
          z <= {{WIDTH{1'b0}}, y};
        end
      endcase
    end
  end

  assign valid = (state == FINISH);

endmodule
