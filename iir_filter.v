module iir_filter (
    input wire clk,
    input wire rst_n,
    input wire sample_en,               // 1 kHz enable
    input wire signed [15:0] x_in,      // input signal
    output reg signed [15:0] y_out,     // filtered output
    output reg out_valid
);

    // ===============================
    // Q14 Coefficients
    // ===============================
    localparam signed [31:0] B0 = 588;
    localparam signed [31:0] B1 = 690;
    localparam signed [31:0] B2 = 1053;
    localparam signed [31:0] B3 = 690;
    localparam signed [31:0] B4 = 588;

    localparam signed [31:0] A1 = -30123;
    localparam signed [31:0] A2 = 26089;
    localparam signed [31:0] A3 = -10476;
    localparam signed [31:0] A4 = 1736;

    // ===============================
    // Delay registers
    // ===============================
    reg signed [15:0] x1, x2, x3, x4;
    reg signed [15:0] y1, y2, y3, y4;

    // ===============================
    // Multipliers (48-bit safe)
    // ===============================
    wire signed [47:0] mult_b0 = x_in * B0;
    wire signed [47:0] mult_b1 = x1   * B1;
    wire signed [47:0] mult_b2 = x2   * B2;
    wire signed [47:0] mult_b3 = x3   * B3;
    wire signed [47:0] mult_b4 = x4   * B4;

    wire signed [47:0] mult_a1 = y1 * A1;
    wire signed [47:0] mult_a2 = y2 * A2;
    wire signed [47:0] mult_a3 = y3 * A3;
    wire signed [47:0] mult_a4 = y4 * A4;

    // ===============================
    // Accumulator
    // ===============================
    wire signed [47:0] acc =
        mult_b0 + mult_b1 + mult_b2 + mult_b3 + mult_b4
      - mult_a1 - mult_a2 - mult_a3 - mult_a4;

    // ===============================
    // Scaling (Q14 ? integer)
    // ===============================
    wire signed [31:0] scaled = acc >>> 14;

    // ===============================
    // Saturation (avoid overflow)
    // ===============================
    wire signed [15:0] y_next;

    assign y_next = (scaled > 32767)  ? 16'sd32767 :
                    (scaled < -32768) ? -16'sd32768 :
                    scaled[15:0];

    // ===============================
    // Sequential Logic
    // ===============================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x1 <= 0; x2 <= 0; x3 <= 0; x4 <= 0;
            y1 <= 0; y2 <= 0; y3 <= 0; y4 <= 0;
            y_out <= 0;
            out_valid <= 1'b0;
        end 
        else begin
            if (sample_en) begin
                // Shift input history
                x4 <= x3;
                x3 <= x2;
                x2 <= x1;
                x1 <= x_in;

                // Shift output history
                y4 <= y3;
                y3 <= y2;
                y2 <= y1;
                y1 <= y_next;

                // Output
                y_out <= y_next;
                out_valid <= 1'b1;
            end 
            else begin
                out_valid <= 1'b0;
            end
        end
    end

endmodule