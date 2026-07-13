`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.07.2026 10:35:47
// Design Name: 
// Module Name: tb_baud_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module tb_baud_gen;

    reg  clk;
    reg  rst;
    wire baud_tick;

    baud_gen #(
        .CLK_FREQ   (100_000_000),
        .BAUD_RATE  (9600),
        .OVERSAMPLE (16)
    ) dut (
        .clk      (clk),
        .rst      (rst),
        .baud_tick(baud_tick)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer tick_count;
    time    t0, t1;

    initial begin
        rst        = 1;
        tick_count = 0;
        repeat(10) @(posedge clk);
        rst = 0;

        @(posedge baud_tick); t0 = $time;
        @(posedge baud_tick); t1 = $time;

        $display("Tick period = %0d ns", t1 - t0);
        $display("Expected    = 6510 ns");

        if ((t1 - t0) == 6510)
            $display("PASS");
        else
            $display("FAIL - got %0d ns", t1 - t0);

        repeat(160) @(posedge baud_tick);
        $display("Simulation done");
        $finish;
    end

    always @(posedge clk) begin
        if (rst)
            tick_count <= 0;
        else if (baud_tick)
            tick_count <= tick_count + 1;
    end

    initial begin
        #50_000_000;
        $display("WATCHDOG TIMEOUT");
        $finish;
    end

endmodule
