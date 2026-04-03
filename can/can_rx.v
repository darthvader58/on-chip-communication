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
    output reg        stuff_error
);

    reg        receiving;
    reg [15:0] tick_count;
    reg [5:0]  bit_count;
    reg [51:0] frame_shift;
    wire [51:0] frame_next;

    assign frame_next = {frame_shift[50:0], can_rx};

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
            receiving  <= 1'b0;
            tick_count <= 16'd0;
            bit_count  <= 6'd0;
            frame_shift<= 52'd0;
            id_out     <= 11'd0;
            data_out   <= 8'd0;
            data_valid <= 1'b0;
            crc_error  <= 1'b0;
            stuff_error<= 1'b0;
        end
        else begin
            data_valid  <= 1'b0;
            stuff_error <= 1'b0;

            if (!receiving) begin
                if (can_rx == 1'b0) begin
                    receiving   <= 1'b1;
                    tick_count  <= (BIT_TICKS / 2);
                    bit_count   <= 6'd0;
                    frame_shift <= 52'd0;
                    crc_error   <= 1'b0;
                end
            end
            else begin
                if (tick_count == BIT_TICKS - 1) begin
                    tick_count  <= 16'd0;
                    frame_shift <= frame_next;

                    if (bit_count == 6'd51) begin
                        receiving <= 1'b0;
                        id_out    <= frame_next[50:40];
                        data_out  <= frame_next[32:25];

                        if (frame_next[51] != 1'b0 ||
                            frame_next[39] != 1'b0 ||
                            frame_next[38] != 1'b0 ||
                            frame_next[37] != 1'b0 ||
                            frame_next[36:33] != 4'b0001 ||
                            frame_next[9] != 1'b1 ||
                            frame_next[7] != 1'b1 ||
                            frame_next[6:0] != 7'b1111111 ||
                            frame_next[24:10] != can_crc15_1byte(frame_next[50:40], frame_next[32:25])) begin
                            crc_error <= 1'b1;
                        end
                        else begin
                            data_valid <= 1'b1;
                        end
                    end
                    else begin
                        bit_count <= bit_count + 6'd1;
                    end
                end
                else begin
                    tick_count <= tick_count + 16'd1;
                end
            end
        end
    end

endmodule
