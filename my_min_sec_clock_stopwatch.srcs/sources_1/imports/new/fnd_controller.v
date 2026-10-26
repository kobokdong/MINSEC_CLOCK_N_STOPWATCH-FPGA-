`timescale 1ns / 1ps

module fnd_controller(
    input clk,
    input reset,
    input tick,
    input digit_en,
    input [1:0] sel,
    input circle_anim,
    input [13:0] seg_data,
    output [3:0] an,
    output [7:0] seg
    );
    wire [3:0] w_d1;
    wire [3:0] w_d10;
    wire [3:0] w_d100;
    wire [3:0] w_d1000;

    bin2bcd4digit u_bin2bcd4digit(
        .seg_data(seg_data),
        .sel(sel),
        .d1(w_d1),
        .d10(w_d10),
        .d100(w_d100),
        .d1000(w_d1000)
    );

    fnd_digit_display u_fnd_digit_display(
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .circle_anim(circle_anim),
        .digit_en(digit_en),
        .d1(w_d1),
        .d10(w_d10),
        .d100(w_d100),
        .d1000(w_d1000),
        .an(an),
        .seg(seg)
    );
endmodule

// in_data: 14 bit fnd에 9999까지 표현하기 위한 bin size
// 0 ~ 9999 천/백/십/일 자리 숫자 0~9 BCD 4 bit 표현
module bin2bcd4digit (
    input [13:0] seg_data,
    input [1:0] sel,
    output [3:0] d1,
    output [3:0] d10,
    output [3:0] d100,
    output [3:0] d1000
);

    assign d1 = seg_data % 10;
    assign d10 = (sel) ? (seg_data / 10) % 10 : (seg_data / 10) % 6;
    assign d100 = (sel) ? (seg_data / 100) % 10 : (seg_data / 60) % 10;
    assign d1000 = (sel) ? (seg_data / 1000) % 10 : (seg_data / 600);
endmodule

module fnd_digit_display (
    input clk,
    input reset,
    input tick,
    input circle_anim,
    input digit_en,
    input [3:0] d1,
    input [3:0] d10,
    input [3:0] d100,
    input [3:0] d1000,
    output reg [3:0] an,
    output reg [7:0] seg
);

    reg [3:0] bcd_data;
    
    reg [1:0] time_sel = 0; // 00 01 10 11 : 1ms 마다 바뀜
    reg [3:0] circle_sel = 0;
    reg [$clog2(200) - 1 : 0] r_200ms_counter;

    wire r_digit_en;
    assign r_digit_en = (an == 4'b1011 && time_sel) ? digit_en : 1'b1;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            circle_sel <= 0;
            time_sel <= 0;
            r_200ms_counter <= 0;
        end
        
        else if (tick) begin
            if(circle_anim) begin
                time_sel <= 0;
                if (r_200ms_counter >= 199) begin
                    r_200ms_counter <= 0;
                    if(circle_sel >= 11) circle_sel <= 0;
                    else circle_sel <= circle_sel + 1;
                end
                else r_200ms_counter <= r_200ms_counter + 1;
            end

            else begin
                circle_sel <= 0;
                r_200ms_counter <= 0;
                // --- 1ms마다 fnd를 display digit 1자리씩 선택하는 logic --- /
                time_sel <= time_sel + 1;
            end 
        end
    end

    always @(*) begin //   sel 값이 변할 때는 언제나 수행한다.
        bcd_data = 4'b0000;
        if(circle_anim) begin
            if (circle_sel == 0 || circle_sel == 9 || circle_sel == 10 || circle_sel == 11) an = 4'b0111;
            else if(circle_sel == 1 || circle_sel == 8) an = 4'b1011;
            else if(circle_sel == 2 || circle_sel == 7) an = 4'b1101;
            else if(circle_sel > 2 && circle_sel < 7) an = 4'b1110;
            else an = 4'b1111;
        end

        else begin
            case (time_sel)
                2'b00: begin
                    bcd_data = d1;
                    an = 4'b1110;
                end
                2'b01: begin
                    bcd_data = d10;
                    an = 4'b1101;
                end
                2'b10: begin
                    bcd_data = d100;
                    an = 4'b1011;
                end
                2'b11: begin
                    bcd_data = d1000;
                    an = 4'b0111;
                end
                default: begin
                    bcd_data = 4'b0000;
                    an = 4'b1111;
                end
            endcase
        end
    end

    // seg 값 설정
    always @(*) begin
        if(circle_anim) begin
            if (circle_sel < 4) seg = 8'b1111_1110;
            else if(circle_sel == 4) seg = 8'b1111_1101;
            else if(circle_sel == 5) seg = 8'b1111_1011;
            else if(circle_sel < 10) seg = 8'b1111_0111;
            else if(circle_sel == 10) seg = 8'b1110_1111;
            else if(circle_sel == 11) seg = 8'b1101_1111;
            else seg = 8'b1111_1111;
        end
        else begin
            case(bcd_data)
                4'd0: seg = {r_digit_en, 7'b100_0000};   // 0
                4'd1: seg = {r_digit_en, 7'b111_1001};   // 1
                4'd2: seg = {r_digit_en, 7'b010_0100};   // 2
                4'd3: seg = {r_digit_en, 7'b011_0000};   // 3
                4'd4: seg = {r_digit_en, 7'b001_1001};   // 4
                4'd5: seg = {r_digit_en, 7'b001_0010};   // 5
                4'd6: seg = {r_digit_en, 7'b000_0010};   // 6
                4'd7: seg = {r_digit_en, 7'b111_1000};   // 7
                4'd8: seg = {r_digit_en, 7'b000_0000};   // 8
                4'd9: seg = {r_digit_en, 7'b001_0000};   // 9
                default: seg = 8'b1111_1111;  // all off  
            endcase
        end 
    end
endmodule