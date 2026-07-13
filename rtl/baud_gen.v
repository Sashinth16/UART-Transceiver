`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.07.2026 10:34:58
// Design Name: 
// Module Name: baud_gen
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


module baud_gen #(
    parameter CLK_FREQ   = 100_000_000,
    parameter BAUD_RATE  = 9600,
    parameter OVERSAMPLE = 16
) (
    input  wire clk,
    input  wire rst,
    output reg  baud_tick
);

    localparam CLKS_PER_TICK = CLK_FREQ / (BAUD_RATE * OVERSAMPLE);

    reg [$clog2(CLKS_PER_TICK)-1:0] count;

    always @(posedge clk) begin
        if (rst) begin
            count     <= 0;
            baud_tick <= 1'b0;
        end else begin
            baud_tick <= 1'b0;
            if (count == CLKS_PER_TICK - 1) begin
                count     <= 0;
                baud_tick <= 1'b1;
            end else begin
                count <= count + 1;
            end
        end
    end

endmodule
