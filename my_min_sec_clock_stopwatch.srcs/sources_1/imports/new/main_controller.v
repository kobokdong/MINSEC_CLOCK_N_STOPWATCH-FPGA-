`timescale 1ns / 1ps

module main_controller(
    input clk,
    input reset,
    input tick,
    input [1:0] sel,
    input [2:0] btn,
    output circle_anim,
    output [13:0] seg_data,
    output [3:0] led
    );
endmodule