`timescale 1ns / 1ps

module top_clock_stopwatch(
    input clk,
    input reset,
    input [2:0] btn,
    output [3:0] an,
    output [7:0] seg,
    output [3:0] led
    );

    parameter SEG_SIZE_CLOCK = $clog2(3600) - 1;
    parameter SEG_SIZE_STOPWATCH = $clog2(10000) - 1;

    wire [SEG_SIZE_CLOCK:0] w_seg_data_clock;
    wire [SEG_SIZE_STOPWATCH:0] w_seg_data_stopwatch;

    wire [2:0] w_clean_btn;
    wire w_tick;
    wire w_circle_anim;
    wire [13:0] w_seg_data;
    wire [1:0] w_sel;
    wire w_digit_en;

    btn_debouncer u_btn_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(btn),  // raw noisy button input
        .clean_btn(w_clean_btn)
    );

    mode_selector u_mode_selector(
        .clk(clk),
        .reset(reset),
        .btn(w_clean_btn),
        .sel(w_sel),
        .led(led)
    );

    tick_generator u_tick_generator(
        .clk(clk),
        .reset(reset),
        .tick(w_tick)
    );

    min_sec_clock u_min_sec_clock(
        .clk(clk),
        .reset(reset),
        .sel(w_sel),
        .tick(w_tick),
        .digit_en(w_digit_en),
        .seg_data(w_seg_data_clock)    // 1 시간 = 3600초
    );

    stopwatch u_stopwatch(
        .clk(clk),
        .reset(reset),
        .tick(w_tick),
        .sel(w_sel),
        .circle_anim(w_circle_anim),
        .seg_data(w_seg_data_stopwatch)    // 1 시간 = 3600초
    );

    // 24 input, 14 output
    mux_clock_or_stopwatch u_mux_clock_or_stopwatch(
        .seg_data_clock(w_seg_data_clock),
        .seg_data_stopwatch(w_seg_data_stopwatch),
        .sel(w_sel),
        .seg_data(w_seg_data)
    );

    fnd_controller u_fnd_controller(
        .clk(clk),
        .reset(reset),
        .sel(w_sel),
        .tick(w_tick),
        .digit_en(w_digit_en),
        .circle_anim(w_circle_anim),
        .seg_data(w_seg_data),
        .an(an),
        .seg(seg)
    );

endmodule
