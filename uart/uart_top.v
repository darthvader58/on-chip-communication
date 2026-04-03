`timescale 1ns / 1ps

module uart_top
(
    input         clk100,
    input  [15:0] sw,
    input         UART_TXD_IN,
    output        UART_RXD_OUT,
    output [15:0] led
);

    wire [7:0] rx_data;
    wire       rx_valid;
    wire       tx_busy;
    wire       tx_done;
    reg        send_d1;
    reg        send_d2;
    reg        tx_start;
    reg [7:0]  rx_latched;

    uart_tx
    #(
        .CLKS_PER_BIT(868)
    )
    U_TX
    (
        .clk(clk100),
        .rst(1'b0),
        .start(tx_start),
        .data_in(sw[7:0]),
        .tx(UART_RXD_OUT),
        .busy(tx_busy),
        .done(tx_done)
    );

    uart_rx
    #(
        .CLKS_PER_BIT(868)
    )
    U_RX
    (
        .clk(clk100),
        .rst(1'b0),
        .rx(UART_TXD_IN),
        .data_out(rx_data),
        .data_valid(rx_valid)
    );

    always @(posedge clk100) begin
        send_d1  <= sw[15];
        send_d2  <= send_d1;
        tx_start <= send_d1 & ~send_d2;
        if (rx_valid) begin
            rx_latched <= rx_data;
        end
    end

    assign led[7:0]   = rx_latched;
    assign led[8]     = tx_busy;
    assign led[9]     = tx_done;
    assign led[10]    = rx_valid;
    assign led[15:11] = 5'b0;

endmodule
