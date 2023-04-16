# Copyright (C) 2021 Dmitriy Nekrasov
#
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
# for more details.
#
# XXX: add annotation
#

set is_Modelsim 0
set name_len [string length [exec bash -c "vsim -version | grep ModelSim || true"]]
if { $name_len > 0 } {
  set is_Modelsim 1
}

vlib work

quit -sim

vlog -sv  ../../avalon_st_if.sv
vlog -sv  ../../ll_sc_fifo.v
vlog -sv  ../../generic_sdp_memory.v
vlog -sv  ../../generic_sc_fifo.v
vlog -sv  ../i2s_channel.sv
vlog -sv  ../i2s_core.sv
vlog -sv  mailbox_demux.sv

vlog -sv  tb.sv

vlog -work work -refresh

vopt +acc -o top_opt tb
vsim top_opt

add log -r /tb/*

#if { $::is_Modelsim == 0 } {
#  vopt +acc -o top_opt tb
#  vsim -quiet top_opt
#} else {
#  vsim -quiet -novopt tb
#}

if [batch_mode] {
  run -all
} else {
  do wave.do
  run -all
}


