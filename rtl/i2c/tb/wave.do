onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/scl
add wave -noupdate /tb/sda
add wave -noupdate -divider -height 50 {New Divider}
add wave -noupdate -radix hexadecimal /tb/dut/i2c_core/amm_sgtl_if/address
add wave -noupdate -radix hexadecimal /tb/dut/i2c_core/amm_sgtl_if/write
add wave -noupdate -radix hexadecimal /tb/dut/i2c_core/amm_sgtl_if/writedata
add wave -noupdate -radix hexadecimal /tb/dut/i2c_core/amm_sgtl_if/read
add wave -noupdate -radix hexadecimal /tb/dut/i2c_core/amm_sgtl_if/readdata
add wave -noupdate -radix hexadecimal /tb/dut/i2c_core/amm_sgtl_if/readdatavalid
add wave -noupdate -radix hexadecimal /tb/dut/i2c_core/amm_sgtl_if/waitrequest
add wave -noupdate -divider -height 50 {New Divider}
add wave -noupdate /tb/dut/ads_routine/knob_level
add wave -noupdate /tb/dut/ads_routine/state
add wave -noupdate /tb/dut/ads_routine/current_knob
add wave -noupdate /tb/dut/ads_routine/knob_read_en
add wave -noupdate -divider -height 50 {New Divider}
add wave -noupdate /tb/dut/sgtl_if/writedata
add wave -noupdate /tb/dut/sgtl_if/readdata
add wave -noupdate /tb/dut/sgtl_if/address
add wave -noupdate /tb/dut/sgtl_if/write
add wave -noupdate /tb/dut/sgtl_if/read
add wave -noupdate /tb/dut/sgtl_if/readdatavalid
add wave -noupdate /tb/dut/sgtl_if/waitrequest
add wave -noupdate /tb/dut/csr_if/read
add wave -noupdate /tb/dut/readreq
add wave -noupdate /tb/dut/readreq_d1
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2454806 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 275
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
WaveRestoreZoom {0 ns} {7140820 ns}
