/**
 * @brief
 *
 * @clk
 * @rstb
 * @data_in
 * @k_in 1 -> input is a control character; 0 -> the date is regular data
 * @disab_scram 1 -> disable scrambling
 * @data_out
 * @k_out 1 -> output is a control character
 */
module scramber_8bits (
    input clk,
    input rstb,
    input [7:0] data_in,
    input k_in,
    input disab_scram,
    output reg [7:0] data_out,
    output k_out
);
  localparam LFSR_INIT = 16'hffff;

  reg [15:0] lfsr, lfsr_nxt;

  wire [15:0] lfsr_int = {
    lfsr[7],
    lfsr[6],
    lfsr[5],
    lfsr[4] ^ lfsr[15],
    lfsr[3] ^ lfsr[14] ^ lfsr[15],
    lfsr[2] ^ lfsr[13] ^ lfsr[14] ^ lfsr[15],
    lfsr[1] ^ lfsr[12] ^ lfsr[13] ^ lfsr[14],
    lfsr[0] ^ lfsr[11] ^ lfsr[12] ^ lfsr[13],
    lfsr[10] ^ lfsr[11] ^ lfsr[12] ^ lfsr[15],
    lfsr[9] ^ lfsr[10] ^ lfsr[11] ^ lfsr[14],
    lfsr[8] ^ lfsr[9] ^ lfsr[10] ^ lfsr[13],
    lfsr[8] ^ lfsr[9] ^ lfsr[12],
    lfsr[8] ^ lfsr[11],
    lfsr[10],
    lfsr[9],
    lfsr[8]
  };

  reg [7:0] data_out_nxt;

  wire initialize_scrambler = (data_in == 8'hbc) && (k_in == 1);
  wire pause_scrambler = (data_in == 8'h1c) && (k_in == 1);

  always_comb begin
    lfsr_nxt = lfsr;
    if (disab_scram | pause_scrambler) begin
      lfsr_nxt = lfsr;
    end else if (initialize_scrambler) begin
      lfsr_nxt = LFSR_INIT;
    end else begin
      lfsr_nxt = lfsr_int;
    end
  end

  always_ff @(posedge clk or negedge rstb) begin
    if (!rstb) begin
      lfsr <= LFSR_INIT;
    end else begin
      lfsr <= lfsr_nxt;
    end
  end

  wire [7:0] data_out_int = {
    data_in[0] ^ lfsr[15],
    data_in[1] ^ lfsr[14],
    data_in[2] ^ lfsr[13],
    data_in[3] ^ lfsr[12],
    data_in[4] ^ lfsr[11],
    data_in[5] ^ lfsr[10],
    data_in[6] ^ lfsr[9],
    data_in[7] ^ lfsr[8]
  };

  always_comb begin
    data_out_nxt = data_out_int;
    if (disab_scram || k_in) begin
      data_out_nxt = data_in;
    end else begin
      data_out_nxt = data_out_int;
    end
  end

  always_ff @(posedge clk or negedge rstb) begin
    if (!rstb) begin
      data_out <= 'd0;
    end else begin
      data_out <= data_out_nxt;
    end
  end


endmodule
