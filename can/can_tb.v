`timescale 1ns / 1ps

module can_tb;

    reg clk;
    reg rst;
    reg start;
    reg [10:0] id_in;
    reg [7:0] data_in;
    wire can_line;
    wire tx_busy;
    wire tx_done;
    wire [10:0] id_out;
    wire [7:0] data_out;
    wire data_valid;
    wire crc_error;
    wire stuff_error;

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
        .can_tx(can_line),
        .busy(tx_busy),
        .done(tx_done)
    );

    can_rx
    #(
        .BIT_TICKS(16)
    )
    DUT_RX
    (
        .clk(clk),
        .rst(rst),
        .can_rx(can_line),
        .id_out(id_out),
        .data_out(data_out),
        .data_valid(data_valid),
        .crc_error(crc_error),
        .stuff_error(stuff_error)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst     = 1'b1;
        start   = 1'b0;
        id_in   = 11'h123;
        data_in = 8'hC3;
        #50;
        rst = 1'b0;

        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (data_valid == 1'b1 || crc_error == 1'b1 || stuff_error == 1'b1);
        #1;
        if (crc_error || stuff_error) begin
            $display("CAN test failed. crc_error=%b stuff_error=%b", crc_error, stuff_error);
            $finish;
        end
        if (id_out !== 11'h123 || data_out !== 8'hC3) begin
            $display("CAN test failed. Expected id=123 data=C3, got id=%h data=%h", id_out, data_out);
            $finish;
        end

        #100;
        $display("CAN test passed. ID=%h DATA=%h", id_out, data_out);
        $finish;
    end

endmodule
