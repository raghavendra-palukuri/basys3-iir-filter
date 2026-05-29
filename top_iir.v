`timescale 1ns / 1ps

module top_iir (
    input wire clk,          // 100 MHz
    input wire btnC,         // reset
    input wire [15:0] sw,    // switches
    output wire [15:0] led,  // LED bar
    output wire [6:0] seg,   // 7-seg
    output wire [3:0] an
);
    parameter SAMPLE_COUNT_MAX = 100000;  // FPGA default
    parameter WINDOW_SIZE      = 1000;
    
    wire rst_n = ~btnC;

    // =============================
    // SAMPLE ENABLE (1 kHz)
    // =============================
    reg [16:0] counter = 0;
    reg sample_en = 0;

    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 0;
            sample_en <= 0;
        end else begin
            if (counter == SAMPLE_COUNT_MAX-1) begin
                counter <= 0;
                sample_en <= 1;
            end else begin
                counter <= counter + 1;
                sample_en <= 0;
            end
        end
    end

    // =============================
    // SIGNAL TABLES
    // =============================
    reg signed [15:0] sig50 [0:19];
    reg signed [15:0] sig350 [0:21];

    initial begin
        sig50[0]=0; sig50[1]=309; sig50[2]=588; sig50[3]=809; sig50[4]=951;
        sig50[5]=1000; sig50[6]=951; sig50[7]=809; sig50[8]=588; sig50[9]=309;
        sig50[10]=0; sig50[11]=-309; sig50[12]=-588; sig50[13]=-809; sig50[14]=-951;
        sig50[15]=-1000; sig50[16]=-951; sig50[17]=-809; sig50[18]=-588; sig50[19]=-309;

        sig350[0]=0; sig350[1]=809; sig350[2]=-951; sig350[3]=309; sig350[4]=588;
        sig350[5]=-1000; sig350[6]=588; sig350[7]=309; sig350[8]=-951; sig350[9]=809;
        sig350[10]=0; sig350[11]=-809; sig350[12]=951; sig350[13]=-309; sig350[14]=-588;
        sig350[15]=1000; sig350[16]=-588; sig350[17]=-309; sig350[18]=951; sig350[19]=-809;
        sig350[20]=0; sig350[21]=809;
    end

    // =============================
    // INDEXING
    // =============================
    reg [4:0] idx50=0, idx350=0;

    always @(posedge clk) begin
        if (!rst_n) begin
            idx50<=0; idx350<=0;
        end else if (sample_en) begin
            idx50  <= (idx50==19)?0:idx50+1;
            idx350 <= (idx350==21)?0:idx350+1;
        end
    end

    // =============================
    // INPUT SELECT
    // =============================
    wire signed [15:0] x_in;

    assign x_in =
        ( sw[0] && !sw[1]) ? sig50[idx50] :
        (!sw[0] &&  sw[1]) ? sig350[idx350] :
                             16'd0;

    // =============================
    // FILTER
    // =============================
    wire signed [15:0] y_out;
    wire out_valid;

    iir_filter filter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .sample_en(sample_en),
        .x_in(x_in),
        .y_out(y_out),
        .out_valid(out_valid)
    );

    // =============================
    // FREQUENCY DETECTION
    // =============================
    reg signed [15:0] prev_sample;
    wire zero_cross = (prev_sample < 0 && x_in >= 0);

    always @(posedge clk) begin
        if (!rst_n)
            prev_sample <= 0;
        else if (sample_en)
            prev_sample <= x_in;
    end

    reg [15:0] freq = 0;
    reg [15:0] cycle_count = 0;
    reg [9:0] sample_count = 0;

    always @(posedge clk) begin
        if (!rst_n) begin
            freq <= 0;
            cycle_count <= 0;
            sample_count <= 0;
        end else if (sample_en) begin

            if (zero_cross)
                cycle_count <= cycle_count + 1;

            if (sample_count == WINDOW_SIZE-1) begin
                freq <= cycle_count;
                cycle_count <= 0;
                sample_count <= 0;
            end else begin
                sample_count <= sample_count + 1;
            end
        end
    end

    // =============================
    // AMPLITUDE DETECTION
    // =============================
    reg [15:0] peak = 0;
    reg [15:0] peak_hold = 0;
    reg [15:0] abs_val;

    always @(posedge clk) begin
        if (!rst_n) begin
            peak <= 0;
            peak_hold <= 0;
        end else if (sample_en) begin

            abs_val <= (y_out < 0) ? -y_out : y_out;

            if (abs_val > peak)
                peak <= abs_val;

            if (sample_count == WINDOW_SIZE-1) begin
                peak_hold <= peak;
                peak <= 0;
            end
        end
    end

    // =============================
    // LED BAR
    // =============================
    reg [15:0] led_reg;

always @(posedge clk) begin
    if (peak_hold == 0)
        led_reg <= 16'b0000000000000000;   // ALL LEDs OFF

    else
        led_reg <= (peak_hold < 100)  ? 16'b0000000000000001 :
                   (peak_hold < 200)  ? 16'b0000000000000011 :
                   (peak_hold < 300)  ? 16'b0000000000000111 :
                   (peak_hold < 400)  ? 16'b0000000000001111 :
                   (peak_hold < 500)  ? 16'b0000000000011111 :
                                        16'b1111111111111111;
end
    

    assign led = led_reg;

    // =============================
    // 7-SEGMENT DISPLAY
    // =============================
    reg [3:0] hundreds, tens, ones;

    always @(*) begin
        hundreds = freq / 100;
        tens     = (freq % 100) / 10;
        ones     = freq % 10;
    end

    reg [1:0] scan = 0;
    reg [19:0] refresh = 0;
    reg [3:0] digit;

    always @(posedge clk)
        refresh <= refresh + 1;

    always @(posedge refresh[15])
        scan <= scan + 1;

    assign an = (scan==0)?4'b1110:
                (scan==1)?4'b1101:
                (scan==2)?4'b1011:
                          4'b0111;

    always @(*) begin
        case(scan)
            0: digit = ones;
            1: digit = tens;
            2: digit = hundreds;
            default: digit = 0;
        endcase
    end

    assign seg =
        (digit==0)?7'b1000000:
        (digit==1)?7'b1111001:
        (digit==2)?7'b0100100:
        (digit==3)?7'b0110000:
        (digit==4)?7'b0011001:
        (digit==5)?7'b0010010:
        (digit==6)?7'b0000010:
        (digit==7)?7'b1111000:
        (digit==8)?7'b0000000:
        (digit==9)?7'b0010000:
                   7'b1111111;

endmodule