# Copyright (C) 2021 Dmitriy Nekrasov
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
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


