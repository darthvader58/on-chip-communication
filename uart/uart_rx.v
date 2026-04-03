`timescale 1ns / 1ps

module uart_rx
#(
    parameter CLKS_PER_BIT = 868
)
(
    input            clk,
    input            rst,
    input            rx,
    output reg [7:0] data_out,
    output reg       data_valid
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
            state      <= STATE_IDLE;
            clk_count  <= 16'd0;
            bit_index  <= 3'd0;
            data_reg   <= 8'd0;
            data_out   <= 8'd0;
            data_valid <= 1'b0;
        end
        else begin
            data_valid <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    clk_count <= 16'd0;
                    bit_index <= 3'd0;
                    if (rx == 1'b0) begin
                        state <= STATE_START;
                    end
                end

                STATE_START: begin
                    if (clk_count == (CLKS_PER_BIT - 1) / 2) begin
                        if (rx == 1'b0) begin
                            clk_count <= 16'd0;
                            state     <= STATE_DATA;
                        end
                        else begin
                            state <= STATE_IDLE;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                STATE_DATA: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count         <= 16'd0;
                        data_reg[bit_index] <= rx;
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
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count  <= 16'd0;
                        data_out   <= data_reg;
                        data_valid <= 1'b1;
                        state      <= STATE_IDLE;
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
