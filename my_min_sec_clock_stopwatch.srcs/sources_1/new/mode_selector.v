`timescale 1ns / 1ps

// (1) Mode Selector
module mode_selector (
    input clk,
    input reset,
    input [2:0] btn,
    output reg [1:0] sel,
    output [3:0] led
    );

    parameter CLOCK = 2'b00;
    parameter STOPWATCH = 2'b01;
    parameter RUN = 2'b10;
    parameter PAUSE = 2'b11;

    reg [1:0] next_state;
    reg prev_btnL;
    reg prev_btnC;
    reg prev_btnR;

    wire btnL_valid;
    wire btnC_valid;
    wire btnR_valid;
    assign btnL_valid = prev_btnL && ~ btn[0]; // btnL이 Low edge일 때 sel 값을 바꿀 거임.
    assign btnC_valid = prev_btnC && ~ btn[1]; // btnL이 Low edge일 때 sel 값을 바꿀 거임.
    assign btnR_valid = prev_btnR && ~ btn[2]; // btnL이 Low edge일 때 sel 값을 바꿀 거임.

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            {prev_btnR, prev_btnC, prev_btnL} <= 0;
            sel <= 0;   // sel이 curr_state 역할
        end
        else begin
            {prev_btnR, prev_btnC, prev_btnL} <= btn;
            sel <= next_state;
        end
    end

    // mode select
    always @(*) begin
        next_state = sel;
        case (sel)
            CLOCK: if(btnL_valid) next_state = STOPWATCH;
            STOPWATCH: begin
                if(btnL_valid) next_state = CLOCK;
                else if(btnR_valid) next_state = RUN;
            end
            RUN: begin
                if(btnR_valid) next_state = STOPWATCH;
                else if(btnC_valid) next_state = PAUSE;
            end
            PAUSE: if(btnC_valid) next_state = RUN;
            default: next_state = CLOCK;
        endcase
    end
    
    assign led = (reset) ? 0 : 4'b0001 << sel;

endmodule
