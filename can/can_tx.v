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
    output reg        can_tx,
    output reg        busy,
    output reg        done
);

    reg [51:0] frame_bits;
    reg [5:0]  bit_pos;
    reg [15:0] tick_count;

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
            frame_bits <= 52'd0;
            bit_pos    <= 6'd0;
            tick_count <= 16'd0;
            can_tx     <= 1'b1;
            busy       <= 1'b0;
            done       <= 1'b0;
        end
        else begin
            done <= 1'b0;

            if (!busy) begin
                can_tx <= 1'b1;
                if (start) begin
                    frame_bits <= {1'b0, id_in, 1'b0, 1'b0, 1'b0, 4'b0001, data_in,
                                   can_crc15_1byte(id_in, data_in), 1'b1, 1'b1, 1'b1, 7'b1111111};
                    bit_pos    <= 6'd51;
                    tick_count <= 16'd0;
                    can_tx     <= 1'b0;
                    busy       <= 1'b1;
                end
            end
            else begin
                if (tick_count == BIT_TICKS - 1) begin
                    tick_count <= 16'd0;
                    if (bit_pos == 6'd0) begin
                        can_tx <= 1'b1;
                        busy   <= 1'b0;
                        done   <= 1'b1;
                    end
                    else begin
                        bit_pos <= bit_pos - 6'd1;
                        can_tx  <= frame_bits[bit_pos - 6'd1];
                    end
                end
                else begin
                    tick_count <= tick_count + 16'd1;
                end
            end
        end
    end

endmodule
