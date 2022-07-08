Summary
-------

This testbench is aimed for observing waveforms, not for automated verification 
(though you can extend it with such stuff). All it does is just converting input
file into internal data queue, streaming this stat through selected DUT.
Then you observe waveforms to see whether ths dut does what you want.

To cover system including perepherial interfaces infrostructure use system_tb
(next dir).


Input file spec
---------------

  - All vaues should be presented in 4 hex symbols, signed, little endian.
    ( 7fff -- max possible value, 8000 -- min possible value ).
  - Onle line -- one value
  - Number of lines is not limited

Run
---

example:

  vsim -do "do make.tcl delta_signal delay" &

it does
  - run vsim
  - compile files in files_tb list
  - use delta_signal file, stream it through delay dut
  - draw wave-delta_signal-delay.do waveform file if it exists or wave.do if it
    exists


KnownIssues
-----------

  - 16-bit hardcode
  - compile function compiles all files in files_tb, including not necessaty duts

Authors
-------

D.Nekrasov

2021

License
-------

GNU GPL V3
