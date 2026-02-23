onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/CLK
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/RST
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/RX_D_VLD
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/RX_P_Data
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/RdData_Valid
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/RdData
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/OUT_Valid
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/ALU_OUT
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/FIFO_FULL
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/WrEN
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/RdEn
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/Address
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/WrData
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/ALU_FUN
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/ALU_EN
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/CLK_EN
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/TX_D_VLD
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/TX_P_DATA
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/current_state
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/next_state
add wave -noupdate -radix hexadecimal /SYS_CTRL_TB/dut/CMD_IN
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {85194 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 284
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {44972 ps} {159404 ps}
