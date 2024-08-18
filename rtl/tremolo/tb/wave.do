onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Analog-Step -height 112 -max 10108.0 -min 10000.0 /tb/dut/data_i
add wave -noupdate -format Analog-Step -height 112 -max 9980.0 -min 5000.0 /tb/dut/data_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 436
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {2100 us}
