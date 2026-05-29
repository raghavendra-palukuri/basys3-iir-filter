`timescale 1ns / 1ps

module tb_top_iir;

    reg clk;
    reg btnC;
    reg [15:0] sw;

    wire [15:0] led;
    wire [6:0] seg;
    wire [3:0] an;

    // Instantiate DUT
    top_iir #(
              .SAMPLE_COUNT_MAX(100),
              .WINDOW_SIZE(100)
              ) uut (
                      .clk(clk),
                      .btnC(btnC),
                      .sw(sw),
                      .led(led),
                      .seg(seg),
                      .an(an)
                     );

    // Clock generation (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    integer i;

    initial begin
        // Reset
        btnC = 1; 
        sw = 0;
        #100;
        btnC = 0;

        // -------------------------
        // Test 50 Hz
        // -------------------------
        sw = 2'b01;

        for(i=0;i<500;i=i+1) begin
            #100000;   // shorter delay (0.1 ms)
            $display("50Hz LED = %b", led);
        end

        // -------------------------
        // Test 350 Hz
        // -------------------------
        sw = 2'b10;

        for(i=0;i<500;i=i+1) begin
            #100000;
            $display("350Hz LED = %b", led);
        end

        $finish;
    end

endmodule 