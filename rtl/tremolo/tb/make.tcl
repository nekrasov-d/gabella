#!/bin/python3
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
# vsim -do make.tcl
#
# -- Dmitry Nekrasov <bluebag@yandex.ru>   Sun, 07 Apr 2024 22:13:40 +0300

vlib work
quit -sim

vlog -quiet -sv ../src/biased_bitstream_generator.sv
vlog -quiet -sv ../src/frequency_control.sv
vlog -quiet -sv ../src/modulator.sv
vlog -quiet -sv ../src/rom.sv
vlog -quiet -sv ../src/tremolo.sv
vlog -quiet -sv ../../cordic_based_math/rtl/cordic_step.sv -suppress 2583
vlog -quiet -sv ../../cordic_based_math/rtl/sincos.sv      -suppress 2583

vlog -quiet -sv tb.sv

vsim -quiet tb -suppress 3116

if [file exists "wave.do"] {
  do wave.do
}

add log -r /tb/*
run -all
