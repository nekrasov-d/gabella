# Copyright (C) 2024 Dmitriy Nekrasov
#
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
# for more details.
#
# ---------------------------------------------------------------------------
#
# Modelsim / Questasim launch file. See README.md for details
#
# Run:
#   vsim -do make.tcl

vlib work
quit -sim
vlog -quiet -sv fake_plls.sv
vlog -quiet -sv ../main_config_pkg.sv
vlog -quiet -sv ../rtl/common/amm_simple_demux.sv
vlog -quiet -sv ../rtl/common/avalon_mm_if.sv
vlog -quiet -sv ../rtl/common/design_interfaces.sv
vlog -quiet -sv ../rtl/common/showahead_sc_fifo.sv
vlog -quiet -sv ../rtl/common/sum_sat.sv
vlog -quiet -sv ../rtl/fir_filter/ram_fir.sv
vlog -quiet -sv ../rtl/fir_filter/ram.sv
vlog -quiet -sv ../rtl/fir_filter/rom.sv
vlog -quiet -sv ../rtl/other_effects/attenuator.sv
vlog -quiet -sv ../rtl/other_effects/chorus.sv
vlog -quiet -sv ../rtl/other_effects/crossfader.sv
vlog -quiet -sv ../rtl/other_effects/delay_reflections_pipeline.sv
vlog -quiet -sv ../rtl/other_effects/delay.sv
vlog -quiet -sv ../rtl/other_effects/limiter.sv
vlog -quiet -sv ../rtl/other_effects/primitive_lowpass_filter.sv
vlog -quiet -sv ../rtl/other_effects/design_under_test.sv
vlog -quiet -sv ../rtl/secondary_logic/i2s_receiver.sv
vlog -quiet -sv ../rtl/secondary_logic/i2s_transmitter.sv
vlog -quiet -sv ../rtl/secondary_logic/led_controller.sv
vlog -quiet -sv ../rtl/secondary_logic/spdif_transmitter.sv
vlog -quiet -sv ../rtl/secondary_logic/spdif_strobe_cdc.sv
vlog -quiet -sv ../rtl/secondary_logic/switch_debouncer.sv
vlog -quiet -sv ../rtl/secondary_logic/i2s_devices_ctrl.sv
vlog -quiet -sv ../rtl/secondary_logic/design_subsystems.sv
vlog -quiet -sv ../rtl/secondary_logic/board_memory/board_memory.sv
vlog -quiet -sv ../rtl/secondary_logic/board_memory/sdram_controller.sv
vlog -quiet -sv ../rtl/secondary_logic/board_memory/sdram_init.sv
vlog -quiet -sv ../rtl/secondary_logic/i2c/i2c_core_pkg.sv
vlog -quiet -sv ../rtl/secondary_logic/i2c/ads_i2c_routine.sv
vlog -quiet -sv ../rtl/secondary_logic/i2c/bit_operation.sv
vlog -quiet -sv ../rtl/secondary_logic/i2c/i2c_core.sv
vlog -quiet -sv ../rtl/secondary_logic/i2c/i2c_subsystem.sv
vlog -quiet -sv ../rtl/tremolo/src/biased_bitstream_generator.sv
vlog -quiet -sv ../rtl/tremolo/src/cordic.sv
vlog -quiet -sv ../rtl/tremolo/src/frequency_control.sv
vlog -quiet -sv ../rtl/tremolo/src/rotator.sv
vlog -quiet -sv ../rtl/tremolo/src/sine_generator.sv
vlog -quiet -sv ../rtl/tremolo/src/tremolo.sv
vlog -quiet -sv ../rtl/audio_engine.sv
vlog -quiet -sv ../rtl/pedalboard.sv
vlog -quiet -sv ../rtl/top.sv
vlog -quiet -sv tb.sv

vsim -quiet tb -suppress 3116

if [file exists "wave.do"] {
  do wave.do
}

add log -r /tb/*
run -all
