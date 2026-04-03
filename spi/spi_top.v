`timescale 1ns / 1ps

module spi_top
(
    input         clk100,
    input  [15:0] sw,
    input         spi_miso,
    output        spi_mosi,
    output        spi_sclk,
    output        spi_cs_n,
    output [15:0] led
);

    reg  start_d1;
    reg  start_d2;
    reg  start_pulse;
    wire [7:0] rx_data;
    wire busy;
    wire done;

    spi_master
    #(
        .CLK_DIVIDER(16)
    )
    DUT
    (
        .clk(clk100),
        .rst(1'b0),
        .start(start_pulse),
        .tx_data(sw[7:0]),
        .miso(spi_miso),
        .sclk(spi_sclk),
        .mosi(spi_mosi),
        .cs_n(spi_cs_n),
        .rx_data(rx_data),
        .busy(busy),
        .done(done)
    );

    always @(posedge clk100) begin
        start_d1    <= sw[15];
        start_d2    <= start_d1;
        start_pulse <= start_d1 & ~start_d2;
    end

    assign led[7:0]   = rx_data;
    assign led[8]     = busy;
    assign led[9]     = done;
    assign led[15:10] = 6'b0;

endmodule
