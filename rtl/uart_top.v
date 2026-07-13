`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.07.2026 11:07:35
// Design Name: 
// Module Name: uart_top
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


module uart_top #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 9600
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] data_in,
    output wire       tx,
    output wire [7:0] data_out,
    output wire       rx_valid,
    output wire       parity_err,
    output wire       tx_busy
);

    // internal wires
    wire baud_tick;

    // baud rate generator
    baud_gen #(
        .CLK_FREQ   (CLK_FREQ),
        .BAUD_RATE  (BAUD_RATE),
        .OVERSAMPLE (16)
    ) baud_inst (
        .clk      (clk),
        .rst      (rst),
        .baud_tick(baud_tick)
    );

    // transmitter
    uart_tx tx_inst (
        .clk      (clk),
        .rst      (rst),
        .baud_tick(baud_tick),
        .tx_start (tx_start),
        .data_in  (data_in),
        .tx       (tx),
        .tx_busy  (tx_busy)
    );

    // receiver - rx input tied to tx output (loopback)
    uart_rx rx_inst (
        .clk       (clk),
        .rst       (rst),
        .baud_tick (baud_tick),
        .rx        (tx),
        .data_out  (data_out),
        .rx_valid  (rx_valid),
        .parity_err(parity_err)
    );

endmodule
