`timescale 1ns / 1ps

module min_sec_clock (
    input clk,
    input reset,
    input [1:0] sel,
    input tick,
    output digit_en,
    output [$clog2(3600) - 1:0] seg_data    // 1 시간 = 3600초
    );

    parameter TICK_IN = 1_000; // 1초에 1,000 번
    parameter TICK_CLOCK = 1;    // 1초에 1번
    parameter TICK_COUNT = TICK_IN / TICK_CLOCK; // 1000 / 1 = 1000

    reg [$clog2(TICK_COUNT) - 1: 0] r_1sec_counter = 0;
    reg [$clog2(3600) - 1:0] time_counter = 0;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_1sec_counter <= 0;
            time_counter <= 0;
        end

        else if (tick) begin
            if(r_1sec_counter >= TICK_COUNT - 1) begin
                r_1sec_counter <= 0;
                if(time_counter >= 3600 - 1) time_counter <= 0;
                else time_counter <= time_counter + 1;
            end
            else r_1sec_counter <= r_1sec_counter + 1;
        end
    end

    assign seg_data = (sel == 0) ? time_counter : 0;
    assign digit_en = (r_1sec_counter < 500 && sel == 0) ? 1'b0 : 1'b1;

endmodule