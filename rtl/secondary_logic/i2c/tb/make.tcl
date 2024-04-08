#!bin/pythion3
#
# MIT License
#
# Copyright (c) 2024 Dmitriy Nekrasov
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ---------------------------------------------------------------------------------
#
# -- Dmitry Nekrasov <bluebag@yandex.ru>   Sun, 07 Apr 2024 18:29:33 +0300

set is_Modelsim 0
set name_len [string length [exec bash -c "vsim -version | grep ModelSim || true"]]
if { $name_len > 0 } {
  set is_Modelsim 1
}

vlib work

quit -sim

vlog -sv  ../reg_fifo.sv
vlog -sv  ../i2c_core_pkg.sv
vlog -sv  ../bit_operation.sv
vlog -sv  ../avalon_mm_if.sv
vlog -sv  ../amm_simple_demux.sv
vlog -sv  ../i2c_core.sv
vlog -sv  ../ads_i2c_routine.sv
vlog -sv  ../sgtl_i2c_routine.sv
vlog -sv  ../i2c_subsystem.sv
vlog -sv  tb.sv

vlog -work work -refresh

vopt +acc -o top_opt tb
vsim top_opt

if { $::is_Modelsim == 0 } {
  vopt +acc -o top_opt tb
  vsim -quiet top_opt
} else {
  vsim -quiet -novopt tb
}

if [batch_mode] {
  run -all
} else {
  do wave.do
  run -all
}


