`timescale 1ns / 1ps

module can_tx
#(
    parameter BIT_TICKS = 200
)
(
    input             clk,
    input             rst,
    input             start,
    input      [10:0] id_in,
    input      [7:0]  data_in,
    input             can_rx,
    output reg        can_tx,
    output reg        busy,
    output reg        done,
    output reg        ack_error,
    output reg        arbitration_lost
);

    reg [41:0] core_bits;
    reg [5:0]  core_pos;
    reg [15:0] tick_count;
    reg [2:0]  state;
    reg [2:0]  eof_count;
    reg [1:0]  ifs_count;
    reg        current_bit;
    reg        last_bit;
    reg [2:0]  same_count;
    reg        stuff_pending;

    localparam STATE_IDLE      = 3'd0;
    localparam STATE_CORE      = 3'd1;
    localparam STATE_ACK_SLOT  = 3'd2;
    localparam STATE_ACK_DELIM = 3'd3;
    localparam STATE_EOF       = 3'd4;
    localparam STATE_IFS       = 3'd5;

    function [14:0] can_crc15_1byte;
        input [10:0] id_value;
        input [7:0] data_value;
        reg [26:0] payload;
        reg [14:0] crc;
        reg feedback;
        integer i;
        begin
            payload = {1'b0, id_value, 1'b0, 1'b0, 1'b0, 4'b0001, data_value};
            crc = 15'd0;
            for (i = 26; i >= 0; i = i - 1) begin
                feedback = payload[i] ^ crc[14];
                crc = {crc[13:0], 1'b0};
                if (feedback) begin
                    crc = crc ^ 15'h4599;
                end
            end
            can_crc15_1byte = crc;
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            core_bits         <= 42'd0;
            core_pos          <= 6'd0;
            tick_count        <= 16'd0;
            state             <= STATE_IDLE;
            eof_count         <= 3'd0;
            ifs_count         <= 2'd0;
            current_bit       <= 1'b1;
            last_bit          <= 1'b1;
            same_count        <= 3'd0;
            stuff_pending     <= 1'b0;
            can_tx            <= 1'b1;
            busy              <= 1'b0;
            done              <= 1'b0;
            ack_error         <= 1'b0;
            arbitration_lost  <= 1'b0;
        end
        else begin
            done <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    can_tx <= 1'b1;
                    busy   <= 1'b0;
                    if (start) begin
                        core_bits        <= {1'b0, id_in, 1'b0, 1'b0, 1'b0, 4'b0001,
                                             data_in, can_crc15_1byte(id_in, data_in)};
                        core_pos         <= 6'd41;
                        tick_count       <= 16'd0;
                        current_bit      <= 1'b0;
                        can_tx           <= 1'b0;
                        last_bit         <= 1'b0;
                        same_count       <= 3'd1;
                        stuff_pending    <= 1'b0;
                        eof_count        <= 3'd0;
                        ifs_count        <= 2'd0;
                        ack_error        <= 1'b0;
                        arbitration_lost <= 1'b0;
                        busy             <= 1'b1;
                        state            <= STATE_CORE;
                    end
                end

                STATE_CORE: begin
                    if (tick_count == (BIT_TICKS / 2)) begin
                        if (core_pos >= 6'd31 && current_bit && !can_rx) begin
                            arbitration_lost <= 1'b1;
                            busy             <= 1'b0;
                            state            <= STATE_IDLE;
                            can_tx           <= 1'b1;
                        end
                    end

                    if (tick_count == BIT_TICKS - 1) begin
                        tick_count <= 16'd0;

                        if (stuff_pending) begin
                            current_bit   <= ~last_bit;
                            can_tx        <= ~last_bit;
                            last_bit      <= ~last_bit;
                            same_count    <= 3'd1;
                            stuff_pending <= 1'b0;
                        end
                        else if (core_pos == 6'd0) begin
                            current_bit <= 1'b1;
                            can_tx      <= 1'b1;
                            state       <= STATE_ACK_SLOT;
                        end
                        else begin
                            core_pos    <= core_pos - 6'd1;
                            current_bit <= core_bits[core_pos - 6'd1];
                            can_tx      <= core_bits[core_pos - 6'd1];

                            if (core_bits[core_pos - 6'd1] == last_bit) begin
                                same_count <= same_count + 3'd1;
                                if (same_count == 3'd4) begin
                                    stuff_pending <= 1'b1;
                                end
                            end
                            else begin
                                same_count <= 3'd1;
                                last_bit   <= core_bits[core_pos - 6'd1];
                            end
                        end
                    end
                    else begin
                        tick_count <= tick_count + 16'd1;
                    end
                end

                STATE_ACK_SLOT: begin
                    can_tx <= 1'b1;
                    if (tick_count == (BIT_TICKS / 2)) begin
                        if (can_rx) begin
                            ack_error <= 1'b1;
                        end
                    end

                    if (tick_count == BIT_TICKS - 1) begin
                        tick_count <= 16'd0;
                        can_tx     <= 1'b1;
                        state      <= STATE_ACK_DELIM;
                    end
                    else begin
                        tick_count <= tick_count + 16'd1;
                    end
                end

                STATE_ACK_DELIM: begin
                    can_tx <= 1'b1;
                    if (tick_count == BIT_TICKS - 1) begin
                        tick_count <= 16'd0;
                        eof_count  <= 3'd0;
                        state      <= STATE_EOF;
                    end
                    else begin
                        tick_count <= tick_count + 16'd1;
                    end
                end

                STATE_EOF: begin
                    can_tx <= 1'b1;
                    if (tick_count == BIT_TICKS - 1) begin
                        tick_count <= 16'd0;
                        if (eof_count == 3'd6) begin
                            ifs_count <= 2'd0;
                            state     <= STATE_IFS;
                        end
                        else begin
                            eof_count <= eof_count + 3'd1;
                        end
                    end
                    else begin
                        tick_count <= tick_count + 16'd1;
                    end
                end

                STATE_IFS: begin
                    can_tx <= 1'b1;
                    if (tick_count == BIT_TICKS - 1) begin
                        tick_count <= 16'd0;
                        if (ifs_count == 2'd2) begin
                            can_tx <= 1'b1;
                            busy   <= 1'b0;
                            done   <= 1'b1;
                            state  <= STATE_IDLE;
                        end
                        else begin
                            ifs_count <= ifs_count + 2'd1;
                        end
                    end
                    else begin
                        tick_count <= tick_count + 16'd1;
                    end
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
