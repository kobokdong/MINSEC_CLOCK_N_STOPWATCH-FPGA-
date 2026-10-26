`timescale 1ns / 1ps

// 아래에 있는 코드는 버튼 디바운서 이다. 
// 이는 noisy_btn 버튼의 입력에서 발생할 수 있는 
// 노이즈(채터링)을 제거해, 안정적인 버튼 입력(clean_btn)으로 만들어준다.
// 파라미터는 보통 클럭 카운트 제한값으로 사용되어,
// 얼마나 오랫동안 입력이 안정적인지를 판단하기 위한 시간 지연 설정이다.
// 예: 100MHz 클럭이라면, 999,999는 약 10ms의 디바운싱 지연을 의미할 수 있다.
module debouncer #(parameter DEBOUNCE_LIMIT = 20'd999_999) (
    input clk,
    input reset,
    input noisy_btn,  // raw noisy button input
    output reg clean_btn
);
    reg [19:0] r_count;
    reg btn_state = 0;
    
    // 버튼 입력 동기화 (버튼은 비동기 입력이기 때문에 setup time, holding time을 지키지 못할 수도 있기 때문에 동기화를 해줘야 한다.)
    (* ASYNC_REG = "TRUE" *) reg btn_meta;
    (* ASYNC_REG = "TRUE" *) reg btn_sync;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            btn_meta <= 1'b0;
            btn_sync <= 1'b0;
        end

        else begin
            btn_meta <= noisy_btn;
            btn_sync <= btn_meta;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin   // active-high reset
            r_count <= 0;
            clean_btn <= 0;
        end

        else begin
            if (btn_sync == clean_btn)
                r_count <= 0; // clear하면 다음 변경을 다시 감지할 수 있음

            else begin
                if (r_count < DEBOUNCE_LIMIT)  // 버튼 상태가 바뀌었지만 아직 안정되지 않은 경우
                    r_count <= r_count + 1;

                else begin  // 상태가 충분히 오랫동안 유지됨(10ms)
                    clean_btn <= btn_sync;
                    r_count <= 0;  // clear하면 다음 변경을 다시 감지할 수 있음
                end
            end
        end
    end
endmodule