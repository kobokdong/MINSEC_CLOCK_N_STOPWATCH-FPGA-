`timescale 1ns / 1ps

module stopwatch (
    input clk,
    input reset,
    input tick,
    input [1:0] sel,
    output reg circle_anim,
    output [$clog2(10_000) - 1:0] seg_data    // 1 시간 = 3600초
    );

    // mode define
    parameter CLOCK = 2'b00;
    parameter STOPWATCH = 2'b01;
    parameter RUN = 2'b10;
    parameter PAUSE = 2'b11;

    // reg [1:0] r_mode = CLOCK;
    reg [3:0] r_1ms_counter ;
    reg [$clog2(10_000)-1:0] r_10ms_counter;    // 10ms counter 9999
    reg [$clog2(5_000)-1:0] r_5sec_counter;
    // sel에 따른 동작

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_10ms_counter <= 0;
            r_1ms_counter <= 0;
            circle_anim <= 0;
            r_5sec_counter <= 0;
        end
            
        else if (sel == STOPWATCH) begin
            r_10ms_counter <= 0;
            r_1ms_counter <= 0;
        end

        else if(sel == RUN) begin
            circle_anim <= 0;
            r_5sec_counter <= 0;
            if (tick) begin
                if(r_1ms_counter >= 9) begin
                    r_1ms_counter <= 0;
                    if (r_10ms_counter >= 9999)
                        r_10ms_counter <= 0;
                    else r_10ms_counter <= r_10ms_counter + 1;
                end
                else r_1ms_counter <= r_1ms_counter + 1;
            end
        end
        
        else if (sel == PAUSE) begin
            if(tick) begin
                if(r_5sec_counter >= 4999) begin
                    r_5sec_counter <= 0;
                    circle_anim <= 1;
                end
                else r_5sec_counter <= r_5sec_counter + 1;
            end
        end
    end

    always @(*) begin
        
    end
    
    assign seg_data = (sel > 0) ? r_10ms_counter : 0;
endmodule