`timescale 1ns / 1ps

module spi_tb;

    reg clk;
    reg rst;
    reg start;
    reg [7:0] tx_data;
    wire sclk;
    wire mosi;
    wire cs_n;
    reg miso;
    wire [7:0] rx_data;
    wire busy;
    wire done;

    reg [7:0] slave_shift;

    spi_master
    #(
        .CLK_DIVIDER(4)
    )
    DUT
    (
        .clk(clk),
        .rst(rst),
        .start(start),
        .tx_data(tx_data),
        .miso(miso),
        .sclk(sclk),
        .mosi(mosi),
        .cs_n(cs_n),
        .rx_data(rx_data),
        .busy(busy),
        .done(done)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        slave_shift = 8'h3C;
        miso        = 1'b0;
    end

    always @(negedge cs_n) begin
        slave_shift <= 8'h3C;
        miso        <= 1'b0;
    end

    always @(negedge sclk) begin
        if (!cs_n) begin
            slave_shift <= {slave_shift[6:0], 1'b0};
            miso        <= slave_shift[6];
        end
    end

    initial begin
        rst     = 1'b1;
        start   = 1'b0;
        tx_data = 8'hA6;
        #40;
        rst = 1'b0;

        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (done == 1'b1);
        #1;
        if (rx_data !== 8'h3C) begin
            $display("SPI test failed. Expected 3C, got %h", rx_data);
            $finish;
        end

        #50;
        $display("SPI test passed. RX data = %h", rx_data);
        $finish;
    end

endmodule
