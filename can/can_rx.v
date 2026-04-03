`timescale 1ns / 1ps

module can_rx
#(
    parameter BIT_TICKS = 200
)
(
    input             clk,
    input             rst,
    input             can_rx,
    output reg [10:0] id_out,
    output reg [7:0]  data_out,
    output reg        data_valid,
    output reg        crc_error,
    output reg        stuff_error,
    output reg        form_error,
    output reg        ack_drive_low
);

    reg [41:0] core_shift;
    reg [5:0]  core_count;
    reg [15:0] tick_count;
    reg [2:0]  state;
    reg [2:0]  eof_count;
    reg [1:0]  ifs_count;
    reg        last_raw_bit;
    reg [2:0]  same_count;
    reg        frame_ok;
    reg [41:0] frame_next;

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
            core_shift    <= 42'd0;
            core_count    <= 6'd0;
            tick_count    <= 16'd0;
            state         <= STATE_IDLE;
            eof_count     <= 3'd0;
            ifs_count     <= 2'd0;
            last_raw_bit  <= 1'b1;
            same_count    <= 3'd0;
            frame_ok      <= 1'b0;
            id_out        <= 11'd0;
            data_out      <= 8'd0;
            data_valid    <= 1'b0;
            crc_error     <= 1'b0;
            stuff_error   <= 1'b0;
            form_error    <= 1'b0;
            ack_drive_low <= 1'b0;
        end
        else begin
            data_valid <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    ack_drive_low <= 1'b0;
                    if (!can_rx) begin
                        core_shift   <= 42'd0;
                        core_count   <= 6'd0;
                        tick_count   <= (BIT_TICKS / 2);
                        last_raw_bit <= 1'b1;
                        same_count   <= 3'd0;
                        frame_ok     <= 1'b0;
                        crc_error    <= 1'b0;
                        stuff_error  <= 1'b0;
                        form_error   <= 1'b0;
                        state        <= STATE_CORE;
                    end
                end

                STATE_CORE: begin
                    if (tick_count == BIT_TICKS - 1) begin
                        tick_count <= 16'd0;

                        if (same_count == 3'd5) begin
                            if (can_rx == last_raw_bit) begin
                                stuff_error <= 1'b1;
                            end
                            last_raw_bit <= can_rx;
                            same_count   <= 3'd1;
                        end
                        else begin
                            frame_next = {core_shift[40:0], can_rx};
                            core_shift <= frame_next;
                            core_count <= core_count + 6'd1;

                            if (same_count == 3'd0) begin
                                same_count   <= 3'd1;
                                last_raw_bit <= can_rx;
                            end
                            else if (can_rx == last_raw_bit) begin
                                same_count <= same_count + 3'd1;
                            end
                            else begin
                                same_count   <= 3'd1;
                                last_raw_bit <= can_rx;
                            end

                            if (core_count == 6'd41) begin
                                id_out   <= frame_next[40:30];
                                data_out <= frame_next[22:15];

                                if (frame_next[41] != 1'b0 ||
                                    frame_next[29] != 1'b0 ||
                                    frame_next[28] != 1'b0 ||
                                    frame_next[27] != 1'b0 ||
                                    frame_next[26:23] != 4'b0001 ||
                                    frame_next[14:0] != can_crc15_1byte(frame_next[40:30],
                                                                         frame_next[22:15])) begin
                                    crc_error <= 1'b1;
                                    frame_ok  <= 1'b0;
                                end
                                else if (!stuff_error) begin
                                    frame_ok <= 1'b1;
                                end
                                state <= STATE_ACK_SLOT;
                            end
                        end
                    end
                    else begin
                        tick_count <= tick_count + 16'd1;
                    end
                end

                STATE_ACK_SLOT: begin
                    ack_drive_low <= frame_ok;
                    if (tick_count == BIT_TICKS - 1) begin
                        tick_count    <= 16'd0;
                        ack_drive_low <= 1'b0;
                        state         <= STATE_ACK_DELIM;
                    end
                    else begin
                        tick_count <= tick_count + 16'd1;
                    end
                end

                STATE_ACK_DELIM: begin
                    if (tick_count == (BIT_TICKS / 2)) begin
                        if (!can_rx) begin
                            form_error <= 1'b1;
                        end
                    end

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
                    if (tick_count == (BIT_TICKS / 2)) begin
                        if (!can_rx) begin
                            form_error <= 1'b1;
                        end
                    end

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
                    if (tick_count == (BIT_TICKS / 2)) begin
                        if (!can_rx) begin
                            form_error <= 1'b1;
                        end
                    end

                    if (tick_count == BIT_TICKS - 1) begin
                        tick_count <= 16'd0;
                        if (ifs_count == 2'd2) begin
                            if (frame_ok && !crc_error && !stuff_error && !form_error) begin
                                data_valid <= 1'b1;
                            end
                            state <= STATE_IDLE;
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
