`timescale 1ns / 1ps


module mux_clock_or_stopwatch #(parameter SEG_SIZE_CLOCK = $clog2(3600) - 1,
                                parameter SEG_SIZE_STOPWATCH = $clog2(10_000) - 1,
                                parameter SEG_SIZE_H = SEG_SIZE_STOPWATCH - SEG_SIZE_CLOCK) (
    input [SEG_SIZE_CLOCK:0] seg_data_clock,
    input [SEG_SIZE_STOPWATCH:0] seg_data_stopwatch,
    input [1:0] sel,
    output [SEG_SIZE_STOPWATCH:0] seg_data
    );

    // sel = 0이면 분초 시계
    // sel = 1이면 stop watch
    assign seg_data = (sel > 0) ? seg_data_stopwatch : {{(SEG_SIZE_H){1'b0}},seg_data_clock};
endmodule
