`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.07.2026 10:49:59
// Design Name: 
// Module Name: tb_uart_rx
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

module tb_uart_rx;

    reg        clk, rst;
    wire       baud_tick;
    wire       tx;
    wire [7:0] data_out;
    wire       rx_valid;
    wire       parity_err;

    reg        tx_start;
    reg  [7:0] data_in;
    wire       tx_busy;

    // baud_gen
    baud_gen #(
        .CLK_FREQ   (100_000_000),
        .BAUD_RATE  (9600),
        .OVERSAMPLE (16)
    ) baud_inst (
        .clk      (clk),
        .rst      (rst),
        .baud_tick(baud_tick)
    );

    // uart_tx - drives the rx input of uart_rx
    uart_tx tx_inst (
        .clk      (clk),
        .rst      (rst),
        .baud_tick(baud_tick),
        .tx_start (tx_start),
        .data_in  (data_in),
        .tx       (tx),
        .tx_busy  (tx_busy)
    );

    // uart_rx - tx wire goes directly into rx input
    uart_rx rx_inst (
        .clk       (clk),
        .rst       (rst),
        .baud_tick (baud_tick),
        .rx        (tx),        // loopback
        .data_out  (data_out),
        .rx_valid  (rx_valid),
        .parity_err(parity_err)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task send_and_check;
        input [7:0] byte_val;
        begin
            @(posedge clk);
            data_in  = byte_val;
            tx_start = 1;
            @(posedge clk);
            tx_start = 0;

            @(posedge rx_valid);
            @(posedge clk);

            if (data_out == byte_val && parity_err == 0)
                $display("PASS - sent 0x%0h, received 0x%0h, parity OK",
                          byte_val, data_out);
            else
                $display("FAIL - sent 0x%0h, received 0x%0h, parity_err=%0b",
                          byte_val, data_out, parity_err);

            repeat(20) @(posedge clk);
        end
    endtask

    initial begin
        rst      = 1;
        tx_start = 0;
        data_in  = 0;
        repeat(10) @(posedge clk);
        rst = 0;
        repeat(5)  @(posedge clk);

        send_and_check(8'h41);   // 'A'
        send_and_check(8'h55);   // 01010101
        send_and_check(8'hFF);   // 11111111
        send_and_check(8'h00);   // 00000000

        $display("All tests done.");
        $finish;
    end

    initial begin
        #50_000_000;
        $display("WATCHDOG TIMEOUT");
        $finish;
    end

endmodule
