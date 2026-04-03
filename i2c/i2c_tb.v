`timescale 1ns / 1ps

module i2c_tb;

    reg clk;
    reg rst;
    reg start;
    wire i2c_scl;
    wire i2c_sda;
    wire busy;
    wire done;
    wire ack_error;

    reg sda_slave_drive_low;
    reg [7:0] bit_count;
    reg [7:0] ack_countdown;
    reg [23:0] captured_bits;

    assign i2c_sda = sda_slave_drive_low ? 1'b0 : 1'bz;

    i2c_master_write
    #(
        .CLK_DIVIDER(8)
    )
    DUT
    (
        .clk(clk),
        .rst(rst),
        .start(start),
        .slave_addr(7'h48),
        .reg_addr(8'h01),
        .reg_data(8'h5A),
        .i2c_scl(i2c_scl),
        .i2c_sda(i2c_sda),
        .busy(busy),
        .done(done),
        .ack_error(ack_error)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        sda_slave_drive_low = 1'b0;
        bit_count           = 8'd0;
        ack_countdown       = 8'd0;
        captured_bits       = 24'd0;
    end

    always @(posedge i2c_scl) begin
        if (busy) begin
            if (ack_countdown == 8'd8) begin
                ack_countdown <= 8'd0;
            end
            else if (bit_count < 8'd24) begin
                captured_bits <= {captured_bits[22:0], (i2c_sda === 1'b0) ? 1'b0 : 1'b1};
                bit_count     <= bit_count + 8'd1;
                ack_countdown <= ack_countdown + 8'd1;
            end
        end
    end

    always @(negedge i2c_scl) begin
        if (busy) begin
            if (ack_countdown == 8'd8) begin
                sda_slave_drive_low <= 1'b1;
            end
            else begin
                sda_slave_drive_low <= 1'b0;
            end
        end
        else begin
            sda_slave_drive_low <= 1'b0;
        end
    end

    initial begin
        rst   = 1'b1;
        start = 1'b0;
        #40;
        rst = 1'b0;

        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (done == 1'b1);
        #1;
        if (ack_error !== 1'b0) begin
            $display("I2C test failed. ACK error asserted.");
            $finish;
        end
        if (captured_bits !== 24'h90015A) begin
            $display("I2C test failed. Expected 90015A, got %h", captured_bits);
            $finish;
        end

        #50;
        $display("I2C test passed. Captured stream = %h", captured_bits);
        $finish;
    end

endmodule
