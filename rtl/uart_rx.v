`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.07.2026 10:48:41
// Design Name: 
// Module Name: uart_rx
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


module uart_rx (
    input  wire       clk,
    input  wire       rst,
    input  wire       baud_tick,
    input  wire       rx,
    output reg  [7:0] data_out,
    output reg        rx_valid,
    output reg        parity_err
);

    localparam IDLE   = 3'd0;
    localparam START  = 3'd1;
    localparam DATA   = 3'd2;
    localparam PARITY = 3'd3;
    localparam STOP   = 3'd4;

    reg [2:0] state;
    reg [3:0] tick_count;   // counts ticks within each bit
    reg [2:0] bit_index;    // which data bit we are receiving
    reg [7:0] shift_reg;    // builds up received byte
    reg       parity_bit;   // received parity bit

    always @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            tick_count <= 0;
            bit_index  <= 0;
            shift_reg  <= 0;
            parity_bit <= 0;
            data_out   <= 0;
            rx_valid   <= 0;
            parity_err <= 0;
        end else begin
            rx_valid <= 1'b0;   // default - only pulses for 1 cycle

            case (state)

                IDLE: begin
                    tick_count <= 0;
                    bit_index  <= 0;
                    if (rx == 1'b0) begin   // falling edge = start bit
                        state <= START;
                    end
                end

                START: begin
                    if (baud_tick) begin
                        if (tick_count == 7) begin
                            // mid-point of start bit
                            // verify it is still 0 (not a glitch)
                            if (rx == 1'b0) begin
                                tick_count <= 0;
                                state      <= DATA;
                            end else begin
                                state <= IDLE;  // was a glitch, abort
                            end
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                end

                DATA: begin
                    if (baud_tick) begin
                        if (tick_count == 15) begin
                            // sample at mid-bit (every 16 ticks after start)
                            shift_reg[bit_index] <= rx;
                            tick_count           <= 0;
                            if (bit_index == 7) begin
                                state <= PARITY;
                            end else begin
                                bit_index <= bit_index + 1;
                            end
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                end

                PARITY: begin
                    if (baud_tick) begin
                        if (tick_count == 15) begin
                            parity_bit <= rx;   // sample parity bit
                            tick_count <= 0;
                            state      <= STOP;
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                end

                STOP: begin
                    if (baud_tick) begin
                        if (tick_count == 15) begin
                            if (rx == 1'b1) begin   // valid stop bit
                                data_out   <= shift_reg;
                                rx_valid   <= 1'b1;
                                parity_err <= (^shift_reg != parity_bit);
                            end
                            tick_count <= 0;
                            state      <= IDLE;
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule