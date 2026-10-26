# top_clock_stopwatch 기능 테스트

`tb_top_clock_stopwatch.v`는 버튼 입력을 구동하고 기대값을 자동 비교합니다.
RTL 소스는 변경하지 않습니다. 실패를 무시하기 위한 내부 신호 강제 설정도 없습니다.

## 실행

Vivado에서 프로젝트를 열고 Simulation Sources의 `tb_top_clock_stopwatch`를
Top으로 지정한 뒤 **Run Behavioral Simulation → Run All**을 실행합니다.
기본 1,000ns 실행만으로는 전체 테스트가 끝나지 않으므로 Run All이 필요합니다.

프로젝트 폴더가 현재 경로인 Vivado Tcl Console에서는 다음 명령으로 실행할 수 있습니다.

```tcl
source ./my_min_sec_clock_stopwatch.srcs/sim_1/new/run_requirements.tcl
```

성공하면 `[PASS] All scenarios passed`가 출력됩니다.
실패하면 `[FAIL]`에 시각, 누적 tick, 실패 항목을 출력하고 마지막에 `$fatal`로 종료합니다.
반복 오류는 처음 20개만 출력하되 전체 실패 횟수는 계속 집계합니다.
100초의 기능 시간 내에 끝나지 않으면 watchdog이 종료합니다.

## 검사 항목

- reset 후 CLOCK 모드와 LED, 분·초 FND 출력 및 00:59 → 01:00 변환
- btnL(btn[0])로 STOPWATCH 대기 모드 진입, 네 자리 0000 출력
- btnR(btn[2])로 RUN 진입, 10ms 단위 증가 및 같은 버튼으로 초기화·대기
- btnC(btn[1])로 PAUSE 진입, 값 유지, 같은 버튼으로 값에 이어서 RUN
- 짧은 PAUSE 후 RUN을 거쳐 다시 PAUSE할 때 5초 대기 시간을 새로 계산
- PAUSE 4,999 tick에서는 숫자 표시, 5,000 tick에서 애니메이션 시작
- 숫자 대신 원형 단일 세그먼트 표시, 200 tick마다 12단계 이동 및 순환
- 애니메이션 중 btnC로 RUN 복귀, 애니메이션 종료와 숫자 출력 재개
- RUN에서 btnR로 초기화·대기 후 btnL로 CLOCK 복귀
- STOPWATCH 체류 중에도 시계가 계속 진행하고 복귀 시 누적 시간이 표시됨

버튼은 실제 디바운서와 falling-edge 검출을 거칩니다.
FND는 `an`으로 선택된 자리의 `seg[6:0]`를 매 클럭 검사하며,
각 숫자 표시 검사 구간에 네 자리 모두 스캔되었는지도 확인합니다.
STOPWATCH의 소수점은 꺼져 있어야 합니다.

## 시간 가속

입력 클럭은 100MHz(10ns)를 유지합니다. 테스트벤치의 `defparam`으로
tick 분주값만 20클럭, 버튼 디바운스 제한값은 3으로 줄였습니다.
각 tick의 기능상 의미는 여전히 1ms이므로 시계는 1,000 tick마다 1초,
스톱워치는 10 tick마다 1회 증가하며 5초 대기는 5,000 tick입니다.
파형상의 5초 대기는 1ms에 해당합니다. 실제 하드웨어의 분주·디바운스
시간 자체를 검증하는 테스트는 아닙니다.

## 현재 RTL 확인 사항 및 검증 상태

`stopwatch.v`의 `r_5sec_counter`는 reset에서 초기화되지 않으며
PAUSE를 벗어날 때에도 초기화되지 않습니다. 시뮬레이션에서 X가 유지되어
5초 뒤 애니메이션이 시작되지 않을 수 있고, 초기값만 추가해도 반복 PAUSE의
대기 시간이 누적될 수 있습니다. 테스트는 이 조건을 정상으로 간주하지 않습니다.

Vivado 2020.2의 `xvlog` 분석과 `xelab` 정적 elaboration은 통과했습니다.
이 환경에서는 Vivado 내장 GCC 실행 시 Windows DLL 재할당 오류가 발생하여
시뮬레이션 실행 파일 생성에 실패했습니다. 따라서 전체 시나리오의 실행 결과는
아직 확인하지 못했습니다.
