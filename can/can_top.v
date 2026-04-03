`timescale 1ns / 1ps

module can_top
(
    input         clk100,
    input  [15:0] sw,
    input         can_rx,
    output        can_tx,
    output [15:0] led
);

    reg start_d1;
    reg start_d2;
    reg start_pulse;
    wire tx_busy;
    wire tx_done;
    wire tx_ack_error;
    wire arbitration_lost;
    wire [10:0] rx_id;
    wire [7:0]  rx_data;
    wire rx_valid;
    wire crc_error;
    wire stuff_error;
    wire form_error;
    wire ack_drive_low;

    can_tx
    #(
        .BIT_TICKS(200)
    )
    U_TX
    (
        .clk(clk100),
        .rst(1'b0),
        .start(start_pulse),
        .id_in(11'h123),
        .data_in(sw[7:0]),
        .can_rx(can_rx),
        .can_tx(can_tx),
        .busy(tx_busy),
        .done(tx_done),
        .ack_error(tx_ack_error),
        .arbitration_lost(arbitration_lost)
    );

    can_rx
    #(
        .BIT_TICKS(200)
    )
    U_RX
    (
        .clk(clk100),
        .rst(1'b0),
        .can_rx(can_rx),
        .id_out(rx_id),
        .data_out(rx_data),
        .data_valid(rx_valid),
        .crc_error(crc_error),
        .stuff_error(stuff_error),
        .form_error(form_error),
        .ack_drive_low(ack_drive_low)
    );

    always @(posedge clk100) begin
        start_d1    <= sw[15];
        start_d2    <= start_d1;
        start_pulse <= start_d1 & ~start_d2;
    end

    assign led[7:0]   = rx_data;
    assign led[8]     = rx_valid;
    assign led[9]     = tx_busy;
    assign led[10]    = tx_done;
    assign led[11]    = tx_ack_error;
    assign led[12]    = arbitration_lost;
    assign led[13]    = crc_error;
    assign led[14]    = stuff_error;
    assign led[15]    = form_error;

endmodule
