`timescale 1ns / 1ps

module i2c_master_write
#(
    parameter CLK_DIVIDER = 250
)
(
    input            clk,
    input            rst,
    input            start,
    input      [6:0] slave_addr,
    input      [7:0] reg_addr,
    input      [7:0] reg_data,
    inout            i2c_scl,
    inout            i2c_sda,
    output reg       busy,
    output reg       done,
    output reg       ack_error
);

    reg scl_drive_low;
    reg sda_drive_low;
    reg [3:0] state;
    reg [15:0] clk_count;
    reg [23:0] shift_reg;
    reg [5:0]  bits_left;
    reg [3:0]  bits_left_in_byte;

    localparam STATE_IDLE      = 4'd0;
    localparam STATE_START_A   = 4'd1;
    localparam STATE_START_B   = 4'd2;
    localparam STATE_BIT_SETUP = 4'd3;
    localparam STATE_BIT_HIGH  = 4'd4;
    localparam STATE_BIT_LOW   = 4'd5;
    localparam STATE_ACK_SETUP = 4'd6;
    localparam STATE_ACK_HIGH  = 4'd7;
    localparam STATE_ACK_LOW   = 4'd8;
    localparam STATE_STOP_A    = 4'd9;
    localparam STATE_STOP_B    = 4'd10;
    localparam STATE_DONE      = 4'd11;

    assign i2c_scl = scl_drive_low ? 1'b0 : 1'bz;
    assign i2c_sda = sda_drive_low ? 1'b0 : 1'bz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_drive_low   <= 1'b0;
            sda_drive_low   <= 1'b0;
            state           <= STATE_IDLE;
            clk_count       <= 16'd0;
            shift_reg       <= 24'd0;
            bits_left       <= 6'd0;
            bits_left_in_byte <= 4'd0;
            busy            <= 1'b0;
            done            <= 1'b0;
            ack_error       <= 1'b0;
        end
        else begin
            done <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b0;
                    clk_count     <= 16'd0;
                    busy          <= 1'b0;
                    if (start) begin
                        shift_reg         <= {slave_addr, 1'b0, reg_addr, reg_data};
                        bits_left         <= 6'd24;
                        bits_left_in_byte <= 4'd8;
                        ack_error         <= 1'b0;
                        busy              <= 1'b1;
                        state             <= STATE_START_A;
                    end
                end

                STATE_START_A: begin
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b0;
                    if (clk_count == CLK_DIVIDER - 1) begin
                        clk_count <= 16'd0;
                        state     <= STATE_START_B;
                    end
                    else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                STATE_START_B: begin
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b1;
                    if (clk_count == CLK_DIVIDER - 1) begin
                        clk_count <= 16'd0;
                        state     <= STATE_BIT_SETUP;
                    end
                    else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                STATE_BIT_SETUP: begin
                    scl_drive_low <= 1'b1;
                    sda_drive_low <= ~shift_reg[23];
                    if (clk_count == CLK_DIVIDER - 1) begin
                        clk_count <= 16'd0;
                        state     <= STATE_BIT_HIGH;
                    end
                    else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                STATE_BIT_HIGH: begin
                    scl_drive_low <= 1'b0;
                    if (clk_count == CLK_DIVIDER - 1) begin
                        clk_count <= 16'd0;
                        state     <= STATE_BIT_LOW;
                    end
                    else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                STATE_BIT_LOW: begin
                    scl_drive_low <= 1'b1;
                    if (clk_count == CLK_DIVIDER - 1) begin
                        clk_count       <= 16'd0;
                        shift_reg       <= {shift_reg[22:0], 1'b0};
                        bits_left       <= bits_left - 6'd1;
                        bits_left_in_byte <= bits_left_in_byte - 4'd1;
                        if (bits_left_in_byte == 4'd1) begin
                            state <= STATE_ACK_SETUP;
                        end
                        else begin
                            state <= STATE_BIT_SETUP;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                STATE_ACK_SETUP: begin
                    scl_drive_low <= 1'b1;
                    sda_drive_low <= 1'b0;
                    if (clk_count == CLK_DIVIDER - 1) begin
                        clk_count <= 16'd0;
                        state     <= STATE_ACK_HIGH;
                    end
                    else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                STATE_ACK_HIGH: begin
                    scl_drive_low <= 1'b0;
                    if (clk_count == CLK_DIVIDER - 1) begin
                        clk_count <= 16'd0;
                        if (i2c_sda != 1'b0) begin
                            ack_error <= 1'b1;
                        end
                        state <= STATE_ACK_LOW;
                    end
                    else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                STATE_ACK_LOW: begin
                    scl_drive_low <= 1'b1;
                    if (clk_count == CLK_DIVIDER - 1) begin
                        clk_count <= 16'd0;
                        if (bits_left == 6'd0) begin
                            state <= STATE_STOP_A;
                        end
                        else begin
                            bits_left_in_byte <= 4'd8;
                            state             <= STATE_BIT_SETUP;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                STATE_STOP_A: begin
                    scl_drive_low <= 1'b1;
                    sda_drive_low <= 1'b1;
                    if (clk_count == CLK_DIVIDER - 1) begin
                        clk_count <= 16'd0;
                        state     <= STATE_STOP_B;
                    end
                    else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                STATE_STOP_B: begin
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b1;
                    if (clk_count == CLK_DIVIDER - 1) begin
                        clk_count     <= 16'd0;
                        sda_drive_low <= 1'b0;
                        state         <= STATE_DONE;
                    end
                    else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                STATE_DONE: begin
                    busy  <= 1'b0;
                    done  <= 1'b1;
                    state <= STATE_IDLE;
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
