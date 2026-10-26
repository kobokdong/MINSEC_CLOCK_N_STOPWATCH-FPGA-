`timescale 1ns / 1ps

// Self-checking integration test. clk remains 100 MHz. One accelerated tick
// represents 1 ms: 5000 ticks = 5 functional seconds, regardless of wall time.
// No force/deposit: uninitialized DUT registers intentionally cause failures.
module tb_top_clock_stopwatch;
    localparam CLOCK = 2'd0, STOPWATCH = 2'd1, RUN = 2'd2, PAUSE = 2'd3;
    localparam TICK_CYCLES = 20;
    reg clk = 0, reset = 0;
    reg [2:0] btn = 0;
    wire [3:0] an, led;
    wire [7:0] seg;
    top_clock_stopwatch dut (
        .clk(clk), .reset(reset), .btn(btn), .an(an), .seg(seg), .led(led)
    );
    defparam dut.u_tick_generator.TICK_COUNT = TICK_CYCLES;
    defparam dut.u_btn_debouncer.btnL_debouncer.DEBOUNCE_LIMIT = 3;
    defparam dut.u_btn_debouncer.btnC_debouncer.DEBOUNCE_LIMIT = 3;
    defparam dut.u_btn_debouncer.btnR_debouncer.DEBOUNCE_LIMIT = 3;
    always #5 clk = ~clk;

    integer errors = 0, checks = 0, tick_total = 0;
    integer clock_ms = 0, clock_seconds = 0, sw_ms = 0, sw_count = 0;
    integer pause_ms = 0;
    reg expected_circle = 0;
    integer display_value, digit_value, digit_index;
    reg [3:0] seen_digits = 0;
    integer saved_sw, entry_tick, saved_clock, i;

    task check;
        input condition;
        input [8*160-1:0] message;
        begin
            checks = checks + 1;
            if (condition !== 1'b1) begin
                errors = errors + 1;
                if (errors <= 20)
                    $display("[FAIL] t=%0t tick=%0d: %0s", $time, tick_total, message);
                if (errors == 21) $display("[FAIL] Further repeated failures suppressed.");
            end
        end
    endtask

    function [6:0] encode_digit;
        input integer value;
        begin
            case (value)
                0: encode_digit = 7'b1000000;
                1: encode_digit = 7'b1111001;
                2: encode_digit = 7'b0100100;
                3: encode_digit = 7'b0110000;
                4: encode_digit = 7'b0011001;
                5: encode_digit = 7'b0010010;
                6: encode_digit = 7'b0000010;
                7: encode_digit = 7'b1111000;
                8: encode_digit = 7'b0000000;
                9: encode_digit = 7'b0010000;
                default: encode_digit = 7'bxxxxxxx;
            endcase
        end
    endfunction

    // Reference counters use consumed tick pulses, never DUT counter values.
    // Mode transitions are checked independently after every button action.
    always @(posedge clk) begin
        if (reset) begin
            tick_total = 0;
            clock_ms = 0;
            clock_seconds = 0;
            sw_ms = 0;
            sw_count = 0;
            pause_ms = 0;
            expected_circle = 0;
        end else begin
            if (dut.w_tick === 1'b1) begin
                tick_total = tick_total + 1;
                clock_ms = clock_ms + 1;
                if (clock_ms == 1000) begin
                    clock_ms = 0;
                    clock_seconds = (clock_seconds + 1) % 3600;
                end
            end
            case (dut.w_sel)
                STOPWATCH: begin sw_ms = 0; sw_count = 0; end
                RUN: if (dut.w_tick === 1'b1) begin
                    sw_ms = sw_ms + 1;
                    if (sw_ms == 10) begin
                        sw_ms = 0;
                        sw_count = (sw_count + 1) % 10000;
                    end
                end
            endcase
            if (dut.w_sel != PAUSE) begin
                pause_ms = 0;
                expected_circle = 0;
            end else if (dut.w_tick === 1'b1) begin
                pause_ms = pause_ms + 1;
                if (pause_ms >= 5000) expected_circle = 1;
            end
            #1; // Sample after nonblocking assignments settle.
            check(dut.u_min_sec_clock.time_counter === clock_seconds,
                  "Clock must keep counting in every mode");
            check(dut.w_seg_data_stopwatch === ((dut.w_sel == CLOCK) ? 14'd0 : sw_count),
                  "Stopwatch must count in RUN, hold in PAUSE, clear in standby");
            check(dut.w_circle_anim === expected_circle,
                  "Circle must start at 5000 PAUSE ticks and clear on RUN");
            // Verify physical multiplexed FND output, not just binary data.
            case (an)
                4'b1110: digit_index = 0;
                4'b1101: digit_index = 1;
                4'b1011: digit_index = 2;
                4'b0111: digit_index = 3;
                default: digit_index = -1;
            endcase
            check(digit_index >= 0, "FND an must select exactly one digit");
            if (dut.w_circle_anim === 1'b0 && digit_index >= 0) begin
                seen_digits[digit_index] = 1;
                if (dut.w_sel == CLOCK)
                    display_value = (clock_seconds / 60) * 100 + clock_seconds % 60;
                else display_value = sw_count;
                case (digit_index)
                    0: digit_value = display_value % 10;
                    1: digit_value = (display_value / 10) % 10;
                    2: digit_value = (display_value / 100) % 10;
                    3: digit_value = (display_value / 1000) % 10;
                endcase
                check(seg[6:0] === encode_digit(digit_value), "FND numeric segment mismatch");
                if (dut.w_sel != CLOCK)
                    check(seg[7] === 1'b1, "Stopwatch decimal point must be off");
            end
        end
    end

    task wait_ticks;
        input integer count;
        integer target;
        begin
            target = tick_total + count;
            while (tick_total < target) begin @(posedge clk); #2; end
        end
    endtask

    task expect_mode;
        input [1:0] mode;
        begin
            check(dut.w_sel === mode, "Unexpected mode after button release");
            check(led === (4'b0001 << mode), "Mode LED mismatch");
        end
    endtask

    task press_button;
        input integer index;
        begin
            // Include synchronizer, debounce and falling-edge detection delays.
            @(negedge clk); btn[index] = 1;
            repeat (12) @(negedge clk);
            btn[index] = 0;
            repeat (12) @(negedge clk);
        end
    endtask

    task check_frame;
        begin
            seen_digits = 0;
            wait_ticks(8);
            check(seen_digits === 4'b1111, "All four numeric FND digits must be scanned");
        end
    endtask

    task check_circle_step;
        input integer step;
        reg [3:0] expected_an;
        reg [7:0] expected_seg;
        begin
            case (step)
                0, 9, 10, 11: expected_an = 4'b0111;
                1, 8: expected_an = 4'b1011;
                2, 7: expected_an = 4'b1101;
                default: expected_an = 4'b1110;
            endcase
            case (step)
                0, 1, 2, 3: expected_seg = 8'hfe;
                4: expected_seg = 8'hfd;
                5: expected_seg = 8'hfb;
                6, 7, 8, 9: expected_seg = 8'hf7;
                10: expected_seg = 8'hef;
                11: expected_seg = 8'hdf;
                default: expected_seg = 8'hff;
            endcase
            check(dut.w_circle_anim === 1'b1, "Animation must remain enabled");
            check(an === expected_an && seg === expected_seg,
                  "Circle must replace digits with the expected moving segment");
        end
    endtask

    initial begin
        $timeformat(-9, 0, " ns", 12);
        $display("[TEST] Default CLOCK and minute/second FND rollover");
        #1; reset = 1;
        repeat (5) @(negedge clk);
        reset = 0;
        repeat (3) @(negedge clk);
        expect_mode(CLOCK);
        check_frame;
        wait_ticks(61200); // Includes 00:59 -> 01:00; outputs checked continuously.
        check(clock_seconds >= 61, "Clock must advance beyond one minute");

        $display("[TEST] btnL -> STOPWATCH, FND 0000");
        press_button(0); expect_mode(STOPWATCH);
        check_frame;
        check(dut.w_seg_data === 14'd0, "Entering stopwatch must display 0000");
        entry_tick = tick_total;
        saved_clock = clock_seconds;

        $display("[TEST] btnR RUN and btnR clear/standby");
        press_button(2); expect_mode(RUN);
        wait_ticks(1234);
        check(sw_count > 0, "RUN must advance stopwatch");
        press_button(2); expect_mode(STOPWATCH);
        check_frame;
        check(dut.w_seg_data === 14'd0, "btnR must clear stopwatch");
        wait_ticks(50);
        check(dut.w_seg_data === 14'd0, "Standby must remain at 0000");

        $display("[TEST] btnC PAUSE and resume before five seconds");
        press_button(2); expect_mode(RUN);
        wait_ticks(321);
        press_button(1); expect_mode(PAUSE);
        saved_sw = sw_count;
        wait_ticks(1000);
        check(dut.w_seg_data === saved_sw, "PAUSE must hold stopwatch value");
        check(dut.w_circle_anim === 1'b0, "No animation before five seconds");
        check_frame;
        press_button(1); expect_mode(RUN);
        wait_ticks(100);
        check(sw_count > saved_sw, "Resume must continue held value");

        $display("[TEST] Fresh PAUSE timeout: 4999 ticks off, 5000 ticks on");
        press_button(1); expect_mode(PAUSE);
        saved_sw = sw_count;
        while (pause_ms < 4999) begin @(posedge clk); #2; end
        check(dut.w_circle_anim === 1'b0, "Animation must be off at 4999 ms");
        wait_ticks(1);
        check(pause_ms == 5000, "Timeout boundary must be exactly 5000 ticks");
        check(dut.w_circle_anim === 1'b1, "Animation must start at 5000 ms");
        check(dut.w_seg_data === saved_sw, "Animation must preserve paused value");

        $display("[TEST] Twelve circle positions, 200 ms per step, wraparound");
        check_circle_step(0);
        for (i = 1; i <= 12; i = i + 1) begin
            wait_ticks(200);
            check_circle_step(i % 12);
        end
        $display("[TEST] btnC exits circle and resumes RUN");
        press_button(1); expect_mode(RUN);
        check(dut.w_circle_anim === 1'b0, "btnC must end circle animation");
        check_frame;
        wait_ticks(100);
        check(sw_count > saved_sw, "Animation exit must resume previous count");

        $display("[TEST] RUN -> btnR standby -> btnL CLOCK, elapsed time retained");
        press_button(2); expect_mode(STOPWATCH);
        check_frame;
        press_button(0); expect_mode(CLOCK);
        check_frame;
        check(tick_total - entry_tick > 5000, "Spend over five seconds in stopwatch");
        check(clock_seconds >= saved_clock + 5, "Clock must include time spent in stopwatch");
        check(dut.w_seg_data === clock_seconds, "Returned clock must show reference elapsed time");
        if (errors == 0) begin
            $display("[PASS] All scenarios passed (%0d checks, %0d functional ms).", checks, tick_total);
            $finish;
        end else begin
            $display("[FAIL] %0d failures in %0d checks.", errors, checks);
            $fatal(1, "top_clock_stopwatch requirements failed");
        end
    end

    initial begin
        #(100000 * TICK_CYCLES * 10);
        $fatal(1, "Watchdog: did not finish within 100 functional seconds");
    end
endmodule
