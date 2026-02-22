if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work


vlog -sv SYS_PKG.sv
vlog -sv ALU/ALU.sv
vlog -sv RegFile/RegFile.sv

vlog -sv UART_TX/UART_TX.sv
vlog -sv UART_RX/strt_check.sv
vlog -sv UART_RX/stop_check.sv
vlog -sv UART_RX/parity_check.sv
vlog -sv UART_RX/edge_bit_counter.sv
vlog -sv UART_RX/data_sampling.sv
vlog -sv UART_RX/deserializer.sv
vlog -sv UART_RX/FSM_RX.sv
vlog -sv UART_RX/UART_RX.sv

vlog -sv ASYNC_FIFO/sync_2ff.sv
vlog -sv ASYNC_FIFO/bin2gray.sv
vlog -sv ASYNC_FIFO/gray2bin.sv
vlog -sv ASYNC_FIFO/fifo_mem.sv
vlog -sv ASYNC_FIFO/rptr_handler.sv
vlog -sv ASYNC_FIFO/wptr_handler.sv
vlog -sv ASYNC_FIFO/async_fifo.sv

vlog -sv "Clock_Dividers/ClkDiv.sv"
vlog -sv "Clock_Gating/CLK_GATE.sv"
vlog -sv "RST_Synchronizer/RST_SYNC.sv"
vlog -sv "Data_Synchronizer/Data_Sync.sv"
vlog -sv PULSE_GEN/PULSE_GEN.sv
vlog -sv DIV_MUX/DIV_MUX.sv
vlog -sv SYS_CTRL/SYS_CTRL.sv

vlog -sv SYS_TOP.sv
vlog -sv SYS_TOP_TB.sv

if {[catch {vlog -sv SYS_TOP_TB.sv} err]} { echo "ERROR: Compilation failed - $err" quit -f}


vsim  -novopt work.SYS_TOP_TBBBB


## -------- Testbench Top-Level --------
add wave -divider "==== TB SIGNALS ===="
add wave -color Gold       /SYS_TOP_TBBBB/REF_CLK
add wave -color Gold       /SYS_TOP_TBBBB/UART_CLK
add wave -color Red        /SYS_TOP_TBBBB/RST_N
add wave -color Cyan       /SYS_TOP_TBBBB/UART_RX_IN
add wave -color Cyan       /SYS_TOP_TBBBB/UART_TX_O
add wave -color Orange     /SYS_TOP_TBBBB/parity_error
add wave -color Orange     /SYS_TOP_TBBBB/framing_error

## -------- Clocks & Resets --------
add wave -divider "==== CLOCKS & RESETS ===="
add wave -color Gold       /SYS_TOP_TBBBB/DUT/RX_CLK
add wave -color Gold       /SYS_TOP_TBBBB/DUT/TX_CLK
add wave -color Gold       /SYS_TOP_TBBBB/DUT/ALU_CLK
add wave -color Red        /SYS_TOP_TBBBB/DUT/SYNC_RST_REF
add wave -color Red        /SYS_TOP_TBBBB/DUT/SYNC_RST_UART

## -------- UART Config --------
add wave -divider "==== UART CONFIG ===="
add wave -color White -radix hex /SYS_TOP_TBBBB/DUT/UART_Config

## -------- SYS_CTRL --------
add wave -divider "==== SYS_CTRL ===="
add wave -color Cyan  /SYS_TOP_TBBBB/DUT/SYNC_RX_VLD
add wave -color Cyan  -radix hex /SYS_TOP_TBBBB/DUT/SYNC_RX_DATA
add wave -color White /SYS_TOP_TBBBB/DUT/WrEn
add wave -color White /SYS_TOP_TBBBB/DUT/WrEn_P
add wave -color White /SYS_TOP_TBBBB/DUT/RdEn
add wave -color White /SYS_TOP_TBBBB/DUT/Gate_EN
add wave -color White /SYS_TOP_TBBBB/DUT/EN
add wave -color White -radix hex /SYS_TOP_TBBBB/DUT/Addr
add wave -color White -radix hex /SYS_TOP_TBBBB/DUT/Wr_D

add wave -color Green -radix hex /SYS_TOP_TBBBB/DUT/U_SYS_CTRL/current_state
add wave -color Green -radix hex /SYS_TOP_TBBBB/DUT/U_SYS_CTRL/next_state


## -------- RegFile --------
add wave -divider "==== REG FILE ===="
add wave -color Magenta -radix hex /SYS_TOP_TBBBB/DUT/Op_A
add wave -color Magenta -radix hex /SYS_TOP_TBBBB/DUT/Op_B
add wave -color Magenta -radix hex /SYS_TOP_TBBBB/DUT/U_RegFile/regfile

## -------- ALU --------
add wave -divider "==== ALU ===="
add wave -color Yellow -radix hex /SYS_TOP_TBBBB/DUT/ALU_FUN
add wave -color Yellow /SYS_TOP_TBBBB/DUT/OUT_Valid
add wave -color Yellow -radix hex /SYS_TOP_TBBBB/DUT/ALU_OUT

## -------- ASYNC FIFO --------
add wave -divider "==== ASYNC FIFO ===="
add wave -color Cyan  /SYS_TOP_TBBBB/DUT/WR_INC
add wave -color Cyan  /SYS_TOP_TBBBB/DUT/FIFO_FULL
add wave -color Cyan  /SYS_TOP_TBBBB/DUT/F_EMPTY
add wave -color Cyan  -radix hex /SYS_TOP_TBBBB/DUT/WR_DATA
add wave -color Cyan  -radix hex /SYS_TOP_TBBBB/DUT/RD_DATA

## -------- UART TX --------
add wave -divider "==== UART TX ===="
add wave -color Orange /SYS_TOP_TBBBB/DUT/BUSY
add wave -color Orange /SYS_TOP_TBBBB/DUT/RD_INC
add wave -color Orange /SYS_TOP_TBBBB/UART_TX_O

## -------- UART RX --------
add wave -divider "==== UART RX ===="
add wave -color Green  /SYS_TOP_TBBBB/UART_RX_IN
add wave -color Green  /SYS_TOP_TBBBB/DUT/RX_OUT_V
add wave -color Green  -radix hex /SYS_TOP_TBBBB/DUT/ASYNC_RX_DATA
add wave -color Green  /SYS_TOP_TBBBB/parity_error
add wave -color Green  /SYS_TOP_TBBBB/framing_error

run -all