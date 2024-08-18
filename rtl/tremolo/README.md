# tremolo-fpga

Simple hardcoded sine wave tremolo for fpga with the lookup table 256-step
frequency control. It contain seeds of design ideas that might be developed into
individual cores, like CORDIC and "leaked bucket" thing.

See tremolo_scheme.png

## Features

  * 256 frequencies availavle (pre-calculated offline, select online)
  * Default settings: 1 to 27.5 Hz with linear interpolated values inbetween
  * 2^x frequency divisor (static configuration).
  * Default setting is 2 (range is 0.5 Hz to 13.75 Hz)
  * 8-bit cordic sine wave generator for the modulation signal.
  * Modulation depth control (8-bit)

## Generate frequency table

python3 generate_frequency_table.py

It produces .mem file, path to this file is should be put into
.FREQ_TABLE_FILE parameter assignment point

## Verification / testing

The testbench provided in tb have no coverage, only raw workability estimation
with waveforms.

The design was verified in the real hardware, works just fine, smooth frequency
switch, no extra noises caused relativaly small cordic bitwidth.

