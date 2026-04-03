`timescale 1ns / 1ps

module can_tb;

    reg clk;
    reg rst;
    reg start;
    reg [10:0] id_in;
    reg [7:0] data_in;
    reg ext_drive_low;
    wire tx_line;
    wire can_bus;
    wire tx_busy;
    wire tx_done;
    wire tx_ack_error;
    wire arbitration_lost;
    wire [10:0] id_out;
    wire [7:0] data_out;
    wire data_valid;
    wire crc_error;
    wire stuff_error;
    wire form_error;
    wire ack_drive_low;

    assign can_bus = tx_line & ~ack_drive_low & ~ext_drive_low;

    can_tx
    #(
        .BIT_TICKS(16)
    )
    DUT_TX
    (
        .clk(clk),
        .rst(rst),
        .start(start),
        .id_in(id_in),
        .data_in(data_in),
        .can_rx(can_bus),
        .can_tx(tx_line),
        .busy(tx_busy),
        .done(tx_done),
        .ack_error(tx_ack_error),
        .arbitration_lost(arbitration_lost)
    );

    can_rx
    #(
        .BIT_TICKS(16)
    )
    DUT_RX
    (
        .clk(clk),
        .rst(rst),
        .can_rx(can_bus),
        .id_out(id_out),
        .data_out(data_out),
        .data_valid(data_valid),
        .crc_error(crc_error),
        .stuff_error(stuff_error),
        .form_error(form_error),
        .ack_drive_low(ack_drive_low)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst          = 1'b1;
        start        = 1'b0;
        id_in        = 11'h123;
        data_in      = 8'hC3;
        ext_drive_low= 1'b0;
        #50;
        rst = 1'b0;

        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (data_valid || tx_ack_error || arbitration_lost || crc_error || stuff_error || form_error);
        #1;
        if (tx_ack_error || arbitration_lost || crc_error || stuff_error || form_error) begin
            $display("CAN frame test failed. ack=%b arb=%b crc=%b stuff=%b form=%b",
                     tx_ack_error, arbitration_lost, crc_error, stuff_error, form_error);
            $finish;
        end
        if (id_out !== 11'h123 || data_out !== 8'hC3) begin
            $display("CAN frame test failed. Expected id=123 data=C3, got id=%h data=%h",
                     id_out, data_out);
            $finish;
        end

        wait (tx_done);
        #100;

        id_in   = 11'h7FF;
        data_in = 8'h55;
        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        repeat (20) @(posedge clk);
        ext_drive_low = 1'b1;
        repeat (20) @(posedge clk);
        ext_drive_low = 1'b0;

        wait (arbitration_lost);
        #20;
        $display("CAN test passed. Frame reception and arbitration detection succeeded.");
        $finish;
    end

endmodule
