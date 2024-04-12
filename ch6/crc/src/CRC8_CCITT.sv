/**
 * @brief 循环冗余校验
 *
 */
module CRC8_CCITT #(
    parameter CRC_INIT_VALUE = 8'hff
) (
    input clk,
    input rstb,
    input din,
    input init_crc,
    input calc_crc,
    output wire [7:0] crc_out
);

  reg [7:0] crcreg, crcreg_nxt;

  wire [7:0] newcrc = {
    crcreg[6],
    crcreg[5],
    crcreg[4],
    crcreg[3],
    crcreg[2],
    (crcreg[7] ^ din) ^ crcreg[1],
    (crcreg[7] ^ din) ^ crcreg[0],
    crcreg[7] ^ din
  };

  always_comb begin
    if (init_crc) begin
      crcreg_nxt = CRC_INIT_VALUE;
    end else if (calc_crc) begin
      crcreg_nxt = crcreg;
    end
  end

  always_ff @(posedge clk or negedge rstb) begin
    if (!rstb) begin
      crcreg <= CRC_INIT_VALUE;
    end else begin
      crcreg <= crcreg_nxt;
    end
  end

  assign crc_out = crcreg;

endmodule
