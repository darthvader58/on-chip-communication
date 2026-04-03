`timescale 1ns / 1ps

module uart_tb;

    reg clk;
    reg rst;
    reg start;
    reg [7:0] data_in;
    wire tx_line;
    wire busy;
    wire done;
    wire [7:0] data_out;
    wire data_valid;

    uart_tx
    #(
        .CLKS_PER_BIT(16)
    )
    DUT_TX
    (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_in(data_in),
        .tx(tx_line),
        .busy(busy),
        .done(done)
    );

    uart_rx
    #(
        .CLKS_PER_BIT(16)
    )
    DUT_RX
    (
        .clk(clk),
        .rst(rst),
        .rx(tx_line),
        .data_out(data_out),
        .data_valid(data_valid)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst     = 1'b1;
        start   = 1'b0;
        data_in = 8'h00;
        #40;
        rst = 1'b0;

        @(posedge clk);
        data_in = 8'hA5;
        start   = 1'b1;
        @(posedge clk);
        start   = 1'b0;

        wait (data_valid == 1'b1);
        #1;
        if (data_out !== 8'hA5) begin
            $display("UART test failed. Expected A5, got %h", data_out);
            $finish;
        end

        #100;
        $display("UART test passed. Received %h", data_out);
        $finish;
    end

endmodule
