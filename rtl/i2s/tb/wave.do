onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/clk
add wave -noupdate /tb/srst
add wave -noupdate /tb/i2s_lrclk
add wave -noupdate /tb/i2s_sclk
add wave -noupdate /tb/i2s_data_in
add wave -noupdate /tb/i2s_data_out
add wave -noupdate -divider -height 50 {New Divider}
add wave -noupdate /tb/dut/gen_left_channel/left_channel/i2s_clk_posedge_i
add wave -noupdate /tb/dut/gen_left_channel/left_channel/i2s_clk_negedge_i
add wave -noupdate -radix unsigned /tb/dut/gen_left_channel/left_channel/posedge_cnt
add wave -noupdate /tb/dut/gen_left_channel/left_channel/input_data_reg
add wave -noupdate /tb/dut/gen_left_channel/left_channel/input_data_wrreq
add wave -noupdate -divider -height 50 {New Divider}
add wave -noupdate /tb/dut/gen_left_channel/left_channel/input_buffer/data_i
add wave -noupdate /tb/dut/gen_left_channel/left_channel/input_buffer/wrreq_i
add wave -noupdate /tb/dut/gen_left_channel/left_channel/input_buffer/rdreq_i
add wave -noupdate /tb/dut/gen_left_channel/left_channel/input_buffer/q_o
add wave -noupdate -divider -height 50 {New Divider}
add wave -noupdate /tb/dut/gen_left_channel/left_channel/output_buffer/data_i
add wave -noupdate /tb/dut/gen_left_channel/left_channel/output_buffer/wrreq_i
add wave -noupdate /tb/dut/gen_left_channel/left_channel/output_buffer/rdreq_i
add wave -noupdate /tb/dut/gen_left_channel/left_channel/output_buffer/q_o
add wave -noupdate /tb/dut/gen_left_channel/left_channel/output_data_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {978754 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 403
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
WaveRestoreZoom {636013 ns} {1094765 ns}
