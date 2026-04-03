`timescale 1ns / 1ps

module i2c_top
(
    input         clk100,
    input  [15:0] sw,
    inout         i2c_scl,
    inout         i2c_sda,
    output [15:0] led
);

    reg start_d1;
    reg start_d2;
    reg start_pulse;
    wire busy;
    wire done;
    wire ack_error;

    i2c_master_write
    #(
        .CLK_DIVIDER(250)
    )
    DUT
    (
        .clk(clk100),
        .rst(1'b0),
        .start(start_pulse),
        .slave_addr(7'h48),
        .reg_addr(8'h01),
        .reg_data(sw[7:0]),
        .i2c_scl(i2c_scl),
        .i2c_sda(i2c_sda),
        .busy(busy),
        .done(done),
        .ack_error(ack_error)
    );

    always @(posedge clk100) begin
        start_d1    <= sw[15];
        start_d2    <= start_d1;
        start_pulse <= start_d1 & ~start_d2;
    end

    assign led[7:0]   = sw[7:0];
    assign led[8]     = busy;
    assign led[9]     = done;
    assign led[10]    = ack_error;
    assign led[15:11] = 5'b0;

endmodule
