`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.07.2026 10:40:16
// Design Name: 
// Module Name: uart_tx
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


module uart_tx (
    input  wire       clk,
    input  wire       rst,
    input  wire       baud_tick,
    input  wire       tx_start,
    input  wire [7:0] data_in,
    output reg        tx,
    output reg        tx_busy
);

  
    localparam IDLE   = 3'd0;
    localparam START  = 3'd1;
    localparam DATA   = 3'd2;
    localparam PARITY = 3'd3;
    localparam STOP   = 3'd4;

    reg [2:0] state;
    reg [3:0] tick_count;   // counts 0 to 15 (16 ticks per bit)
    reg [2:0] bit_index;    // counts 0 to 7  (8 data bits)
    reg [7:0] shift_reg;    // latched copy of data_in
    reg       parity_bit;   // even parity

    always @(posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            tx          <= 1'b1;    // line idles high
            tx_busy     <= 1'b0;
            tick_count  <= 0;
            bit_index   <= 0;
            shift_reg   <= 0;
            parity_bit  <= 0;
        end else begin
            case (state)

                IDLE: begin
                    tx      <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        shift_reg  <= data_in;
                        parity_bit <= ^data_in;  // even parity
                        tick_count <= 0;
                        state      <= START;
                        tx_busy    <= 1'b1;
                    end
                end

                START: begin
                    tx <= 1'b0;      // start bit
                    if (baud_tick) begin
                        if (tick_count == 15) begin
                            tick_count <= 0;
                            bit_index  <= 0;
                            state      <= DATA;
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                end

                DATA: begin
                    tx <= shift_reg[bit_index];   // LSB first
                    if (baud_tick) begin
                        if (tick_count == 15) begin
                            tick_count <= 0;
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
                    tx <= parity_bit;
                    if (baud_tick) begin
                        if (tick_count == 15) begin
                            tick_count <= 0;
                            state      <= STOP;
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                end

                STOP: begin
                    tx <= 1'b1;      // stop bit
                    if (baud_tick) begin
                        if (tick_count == 15) begin
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
