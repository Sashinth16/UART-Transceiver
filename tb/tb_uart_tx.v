`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.07.2026 10:42:02
// Design Name: 
// Module Name: tb_uart_tx
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

module tb_uart_tx;

    reg        clk, rst;
    reg        tx_start;
    reg  [7:0] data_in;
    wire       tx;
    wire       tx_busy;
    wire       baud_tick;

    // baud_gen instance
    baud_gen #(
        .CLK_FREQ   (100_000_000),
        .BAUD_RATE  (9600),
        .OVERSAMPLE (16)
    ) baud_inst (
        .clk      (clk),
        .rst      (rst),
        .baud_tick(baud_tick)
    );

    // uart_tx instance
    uart_tx tx_inst (
        .clk      (clk),
        .rst      (rst),
        .baud_tick(baud_tick),
        .tx_start (tx_start),
        .data_in  (data_in),
        .tx       (tx),
        .tx_busy  (tx_busy)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task send_byte;
        input [7:0] byte_val;
        begin
            @(posedge clk);
            data_in  = byte_val;
            tx_start = 1;
            @(posedge clk);
            tx_start = 0;
            // wait until transmission finishes
            @(negedge tx_busy);
            $display("Sent 0x%0h (%0b) - tx done", byte_val, byte_val);
        end
    endtask

    initial begin
        rst      = 1;
        tx_start = 0;
        data_in  = 0;
        repeat(10) @(posedge clk);
        rst = 0;
        repeat(5)  @(posedge clk);

        send_byte(8'h41);   // 'A' = 01000001
        repeat(20) @(posedge clk);

        send_byte(8'h55);   // 01010101  alternating bits, easy to verify
        repeat(20) @(posedge clk);

        send_byte(8'hFF);   // 11111111
        repeat(20) @(posedge clk);

        $display("All bytes sent. Simulation done.");
        $finish;
    end

    initial begin
        #50_000_000;
        $display("WATCHDOG TIMEOUT");
        $finish;
    end

endmodule
