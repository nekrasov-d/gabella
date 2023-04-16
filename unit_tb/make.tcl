# Copyright (C) 2021 Dmitriy Nekrasov
#
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
# for more details.
#
# unit_tb simulation launch script
#
# Usage:
#    vsim -do "do make.tcl input_file dut"
#

#*****************************************************************************
#***************************** Initialization ********************************

set is_Modelsim 0
set name_len [string length [exec bash -c "vsim -version | grep ModelSim || true"]]
if { $name_len > 0 } {
  set is_Modelsim 1
}

echo "compile Altera sim lib:"
set compile_alt_sim_lib "off"
echo "input file:"
set input_file $1
echo "dut:"
set dut $2
echo "Input file full path:"
set input_file_full_path "[pwd]/$input_file"

#*****************************************************************************
#************************* Utility procedures  *******************************

proc compile_src {} {
  if { $::compile_alt_sim_lib == "on" } {
    set quartus_sim_lib $::env(QUARTUS_SIM_LIB)
    vlog -sv -incr $quartus_sim_lib/altera_mf.v
    vlog -sv -incr $quartus_sim_lib/220model.v
    set $::compile_alt_sim_lib "off"
  }
  vlog -sv -quiet -incr -f files_tb
  vlog -sv -quiet +define+INPUT_FILE="$::input_file_full_path"+DUT="$::dut" unit_tb.sv
  vlog -work work -refresh
}

proc sim {} {
  if { $::is_Modelsim == 0 } {
    vopt +acc -o top_opt unit_tb
    vsim -quiet top_opt
  } else {
    vsim -quiet -novopt unit_tb
  }
}

proc draw {} {
  if { [file exists "wave.do"] } {
    do wave.do
#  } else {
#    set local_wave_file $::input_file + "_" "$::dut" + "wave.do"
#    if { [file exists "$local_wave_file"] } {
#      do "$local_wave_file"
#    }
#  }
}

proc compile_and_run {} {
  compile_src
  sim
  add log -r /unit_tb/*
  draw
  run -all
}


echo "*************************************************************************"
#*****************************************************************************
#*********************************** main  ***********************************

vlib work
quit -sim
compile_and_run

