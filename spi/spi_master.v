`timescale 1ns / 1ps

module spi_master
#(
    parameter CLK_DIVIDER = 8
)
(
    input            clk,
    input            rst,
    input            start,
    input      [7:0] tx_data,
    input            miso,
    output reg       sclk,
    output reg       mosi,
    output reg       cs_n,
    output reg [7:0] rx_data,
    output reg       busy,
    output reg       done
);

    reg [7:0] shift_tx;
    reg [7:0] shift_rx;
    reg [7:0] clk_count;
    reg [3:0] edge_count;
    reg [2:0] bit_index;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sclk      <= 1'b0;
            mosi      <= 1'b0;
            cs_n      <= 1'b1;
            rx_data   <= 8'd0;
            busy      <= 1'b0;
            done      <= 1'b0;
            shift_tx  <= 8'd0;
            shift_rx  <= 8'd0;
            clk_count <= 8'd0;
            edge_count<= 4'd0;
            bit_index <= 3'd7;
        end
        else begin
            done <= 1'b0;

            if (!busy) begin
                sclk      <= 1'b0;
                cs_n      <= 1'b1;
                clk_count <= 8'd0;
                edge_count<= 4'd0;
                bit_index <= 3'd7;
                if (start) begin
                    busy     <= 1'b1;
                    cs_n     <= 1'b0;
                    shift_tx <= tx_data;
                    shift_rx <= 8'd0;
                    mosi     <= tx_data[7];
                end
            end
            else begin
                if (clk_count == CLK_DIVIDER - 1) begin
                    clk_count <= 8'd0;
                    sclk      <= ~sclk;
                    edge_count<= edge_count + 4'd1;

                    if (sclk == 1'b0) begin
                        shift_rx[bit_index] <= miso;
                        if (bit_index == 3'd0) begin
                            rx_data <= {shift_rx[7:1], miso};
                        end
                    end
                    else begin
                        if (bit_index != 3'd0) begin
                            bit_index <= bit_index - 3'd1;
                            mosi      <= shift_tx[bit_index - 3'd1];
                        end
                    end

                    if (edge_count == 4'd15) begin
                        busy <= 1'b0;
                        cs_n <= 1'b1;
                        sclk <= 1'b0;
                        done <= 1'b1;
                    end
                end
                else begin
                    clk_count <= clk_count + 8'd1;
                end
            end
        end
    end

endmodule
