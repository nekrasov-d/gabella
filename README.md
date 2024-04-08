GABELLA
=======

A FPGA guitar processing pedal on cyc1000 board with Cyclone-10 chip on board.

This is a research project with real hardware implementation.


Firmware
--------

Main properties
  -- Mono audio stream
  -- 44100 Hz sampling frequency
  -- 25 MHz system frequency
  -- Negligible internal data delay (less than 1 us)
  -- 24 bit encoding (can be switched to 16)


Source code hierarchy:

  * top.sv : contains basic system routine abstract to the design purpose:
    clock casting, resets, petepherial init control, board memory controller,
    debouncers, etc. This logic i

    * top_wrapper.sv : this module is supposed to be a top level of the
      simulation DUT (but the whole system coverage remains only planned)
      Here we have i2c/i2s interface attachment, remapping, boundary audio
      controls, etc. to make the next level abstract from the platform

      * application_core.sv : aka pedalboard. A chain of effects abstract from
        the hardware. Here we have commutation, on/off switching

        * delay
        * chorus
        * reverb
        * swell
        * a lot in plan


Features
--------

### Delay ###

Status: works

Controls: time, feedback

### Chorus ###

Status: works

Controls: mix

### Swell ###

A BOSS slow gear analog

Status: on debug

Controls: sensetivity

### Reverb ###

Status: in progress

Controls: mix, decay

### Drive ###

Status: abandoned

An attempt to make a cool-sounding overdrive with an logarithmic transfer
function on ROM. I didn't managed to make it sound well, so I abandonned this
idea. It also don't fit into 24-bit design as the 24bit address table requires
too much built-in memory.

There's a script been used to generate ROM image, see scripts/gen_transfer.py

Firmware issues
---------------

  * Only 1 of DRAM banks works, idk why. 1 bank is enough yet though
  * Can work with DRAM only at low 33 Mhz without bit errors (timing constraints
    sucks probably), yet it is still enouth.


Hardware
--------

 - cyc1000 module attached to carry board
 - carry board with
   - PCM1808 ADC which streams 24-bit sound samples at 44100 Hz into fpga via I2S
   -         DAC which recieves 24-bit sound samples at 44100 Hz from fpga via I2S
   - ADS... slow ADC on i2c bus to read 8-bit potentiometer values
   - 8 potentiometers
   - 2 soft buttons
   - 1 switch
   - 1 relay to shortcut audo input to output when design isn't functional

Authors
-------

Dmitriy Nekrasov

License
-------

MIT
