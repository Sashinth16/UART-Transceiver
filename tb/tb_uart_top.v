`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.07.2026 11:08:20
// Design Name: 
// Module Name: tb_uart_top
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

module tb_uart_top;

    reg        clk, rst;
    reg        tx_start;
    reg  [7:0] data_in;
    wire       tx;
    wire [7:0] data_out;
    wire       rx_valid;
    wire       parity_err;
    wire       tx_busy;

    // instantiate top level
    uart_top #(
        .CLK_FREQ  (100_000_000),
        .BAUD_RATE (9600)
    ) dut (
        .clk       (clk),
        .rst       (rst),
        .tx_start  (tx_start),
        .data_in   (data_in),
        .tx        (tx),
        .data_out  (data_out),
        .rx_valid  (rx_valid),
        .parity_err(parity_err),
        .tx_busy   (tx_busy)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // test vectors
    reg [7:0] test_vec [0:4];
    integer i;
    integer pass_count;
    integer fail_count;

    initial begin
        test_vec[0] = 8'h41;   // 'A'
        test_vec[1] = 8'h55;   // 01010101
        test_vec[2] = 8'hFF;   // 11111111
        test_vec[3] = 8'h00;   // 00000000
        test_vec[4] = 8'hA5;   // 10100101

        pass_count = 0;
        fail_count = 0;
    end

    initial begin
        rst      = 1;
        tx_start = 0;
        data_in  = 0;
        repeat(10) @(posedge clk);
        rst = 0;
        repeat(5)  @(posedge clk);

        for (i = 0; i < 5; i = i + 1) begin
            // send byte
            @(posedge clk);
            data_in  = test_vec[i];
            tx_start = 1;
            @(posedge clk);
            tx_start = 0;

            // wait for rx to complete
            @(posedge rx_valid);
            @(posedge clk);

            // check result
            if (data_out == test_vec[i] && parity_err == 0) begin
                $display("PASS [%0d] - sent 0x%0h  received 0x%0h  parity OK",
                          i, test_vec[i], data_out);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL [%0d] - sent 0x%0h  received 0x%0h  parity_err=%0b",
                          i, test_vec[i], data_out, parity_err);
                fail_count = fail_count + 1;
            end

            repeat(20) @(posedge clk);
        end

        $display("─────────────────────────────");
        $display("RESULTS: %0d PASS  %0d FAIL", pass_count, fail_count);
        $display("─────────────────────────────");
        $finish;
    end

    initial begin
        #100_000_000;
        $display("WATCHDOG TIMEOUT");
        $finish;
    end

endmodule