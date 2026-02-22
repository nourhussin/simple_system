# simple_system
a small FPGA-based processing system that integrates an ALU, register file, and UART communication with asynchronous FIFO for clock-domain crossing. It allows receiving commands/data via UART, performing arithmetic/logic operations, and sending results back over UART.


# SystemVerilog Constructs Used 

| Construct | Where Used | Benefit |
|-----------|-----------|---------|
| `package` / `endpackage` | `SYS_PKG.sv` | Centralizes shared definitions (types, parameters) in one place; any module that imports the package gets them automatically without copy-pasting |
| `import SYS_PKG::*` | Top-level modules | Wildcard import brings every exported symbol into scope; eliminates redundant re-declarations across files |
| `typedef logic [7:0] dataframe_t` | `SYS_PKG.sv` | Creates a semantic alias for an 8-bit data word; port declarations read as intent (`dataframe_t`) instead of raw bit-widths |
| `typedef enum logic [3:0] { ... } opcode_t` | `SYS_PKG.sv`, `ALU.sv`, `SYS_CTRL.sv` | Encodes ALU operations as named constants; eliminates magic numbers, enables compiler checks for unhandled enum values, and makes waveforms readable by name instead of hex |
| `typedef enum logic [3:0] { IDLE, CMD, ... } state_t` | `SYS_CTRL.sv` | Same benefits as `opcode_t` applied to FSM states; simulator displays state names in waveform viewer instead of raw 4-bit values |
| `logic` (replaces `wire`/`reg`) | All modules — ports and internal signals | Four-state type (`0`, `1`, `X`, `Z`) usable for both combinational and sequential signals; removes the ambiguity of choosing `wire` vs `reg` and prevents multiple-driver simulation issues |
| `logic [N-1:0]` packed arrays | `ALU_OUT`, `RX_P_Data`, `UART_Config`, etc. | Contiguous bit-vector; supports part-selects and bit operations cleanly |
| `'0`, `'1` (unsized literals) | `ALU.sv`, `SYS_CTRL.sv` | Width-inferred zero/one fill; `ALU_OUT <= '0` works regardless of `DATA_WIDTH`, making it parameter-safe |
| `always_ff @(posedge CLK or negedge RST)` | All sequential logic — `SYS_CTRL`, `ALU`, `RegFile`, `RST_SYNC`, `PULSE_GEN`, `DATA_SYNC` | Declares intent as flip-flop logic; tool enforces that only non-blocking assignments (`<=`) appear inside; synthesis and linting tools flag any combinational feedback automatically |
| `always_comb` | Next-state logic and output logic in `SYS_CTRL`, `DIV_MUX`, `parity_check`, `strt_check`, `stop_check` | Declares intent as purely combinational; sensitivity list is auto-derived so no missing-signal bugs; tools error on latches inferred inside |
| `always @(*)` | Legacy blocks in original Verilog reference | Verilog equivalent of `always_comb`; kept for compatibility but superseded by `always_comb` in the converted SV version |
| Enum-typed state variables (`state_t current_state, next_state`) | `SYS_CTRL.sv`, `FSM_RX.sv` | State variables carry type information; assigning an out-of-range value is a compile-time error; waveform viewer shows state name, not encoding |
| `input logic` / `output logic` ports | All modules | Unified port type; no need to declare separate `wire` nets at instantiation; synthesizable and simulation-equivalent |