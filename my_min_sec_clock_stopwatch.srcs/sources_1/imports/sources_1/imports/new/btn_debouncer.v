`timescale 1ns / 1ps

// 아래에 있는 코드는 버튼 디바운서 이다. 
// 이는 noisy_btn 버튼의 입력에서 발생할 수 있는 
// 노이즈(채터링)을 제거해, 안정적인 버튼 입력(clean_btn)으로 만들어준다.
// 파라미터는 보통 클럭 카운트 제한값으로 사용되어,
// 얼마나 오랫동안 입력이 안정적인지를 판단하기 위한 시간 지연 설정이다.
// 예: 100MHz 클럭이라면, 999,999는 약 10ms의 디바운싱 지연을 의미할 수 있다.
module btn_debouncer(
    input clk,
    input reset,
    input [2:0] noisy_btn,  // raw noisy button input
    output [2:0] clean_btn
);

    debouncer btnL_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_btn[0]),  // raw noisy button input
        .clean_btn(clean_btn[0])
    );

    debouncer btnC_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_btn[1]),  // raw noisy button input
        .clean_btn(clean_btn[1])
    );

    debouncer btnR_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(noisy_btn[2]),  // raw noisy button input
        .clean_btn(clean_btn[2])
    );
endmodule

