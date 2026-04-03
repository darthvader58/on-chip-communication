`timescale 1ns / 1ps

module uart_tx
#(
    parameter CLKS_PER_BIT = 868
)
(
    input            clk,
    input            rst,
    input            start,
    input      [7:0] data_in,
    output reg       tx,
    output reg       busy,
    output reg       done
);

    reg [1:0] state;
    reg [15:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] data_reg;

    localparam STATE_IDLE  = 2'd0;
    localparam STATE_START = 2'd1;
    localparam STATE_DATA  = 2'd2;
    localparam STATE_STOP  = 2'd3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= STATE_IDLE;
            clk_count <= 16'd0;
            bit_index <= 3'd0;
            data_reg  <= 8'd0;
            tx        <= 1'b1;
            busy      <= 1'b0;
            done      <= 1'b0;
        end
        else begin
            done <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    tx        <= 1'b1;
                    busy      <= 1'b0;
                    clk_count <= 16'd0;
                    bit_index <= 3'd0;
                    if (start) begin
                        busy     <= 1'b1;
                        data_reg <= data_in;
                        state    <= STATE_START;
                    end
                end

                STATE_START: begin
                    tx <= 1'b0;
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;
                        state     <= STATE_DATA;
                    end
                    else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                STATE_DATA: begin
                    tx <= data_reg[bit_index];
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;
                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state     <= STATE_STOP;
                        end
                        else begin
                            bit_index <= bit_index + 3'd1;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                STATE_STOP: begin
                    tx <= 1'b1;
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;
                        busy      <= 1'b0;
                        done      <= 1'b1;
                        state     <= STATE_IDLE;
                    end
                    else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
