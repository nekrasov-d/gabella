# GABELLA #

![Main image](https://raw.githubusercontent.com/nekrasov-d/gabella/main/img/gabella.jpg)

Special thanks to my friend Ivan Lypar for analog PCB design and inspiration.

### Synopsys ###

This is a closed research project with real hardware implementation. We never
had any plans to go on market with such stuff.

Goals:

  * Get the experience of making a device from scratch
  * Research possibilities of making audio effects on an FPGA platform
  * Have some fun in progress
  * Actually use it in practice after that

Achieved:

  * We have got the real device. I wouldn't recommend anyone to take it on stage
  because it has some hardware problems making it not enough reliable. But it is
  good enough to use it at home in one chain with commercial devices.
  * The state, preserved in 7cd01a0d commit and corresponding 0.0.1 release is
  called "final", although of course I can get back to this project later, or
  anyone else can continue it. The features that made their way into the final
  firmware:
    - Short time delay / ring mod
    - Chorus
    - Tremolo with knob period control and period time control
    - Set of beat patterns for tremolo (filtered and unfiltered signal
    interleave)
    - Noisy overtone generator based on failed frequency domain system (aka
    Frequency Machine)

Not achieved:
  * Nice sounding frequency domain stuff (reverberation / tone sustain
  polyphonic octave generator). I think I was close but I have already spent too
  much time on this. The bet was on the sliding window Fourier transform, but
  there was big disadvantages discovered (due to fixed point implementation and
  error accumulation due to it's recursive nature). I think I would redo this as
  a regular Cooley-Tukey FFT the next time.

Conclusions:
  * It was interesting to do it the first time. But besides this interest -- it
  doesn't worth it, really. Even knowing my mistakes and being sure that I can
  do a lot better if I invest more time into this project, I would prefer to try
  DSP processors (as 'adults' do).

### Hardware ###

See pcb/gabella.pdf

##### CYC1000 ######

[CYC1000](https://www.arrow.com/en/campaigns/arrow-cyc1000) is a small and cute
DEV board made by Arrow (or Trenz electronics gmbh, honestly, I am still unsure
who is the OEM). It has Intel Fpga Cyclone 10 10CL025YU256C8G on board, 8 Mbytes
of SDRAM and also accelerometer chip (the only part of this board which was an
extra one). The key feature is the size and the way it can be embedded into some
compact device, such as audio processor.

Three years after choosing this one, I still can't see a better candidate for
such project. The most of FPGA boards are intended to be kept on your table,
rather than being embedded.

Of course, I was not fully satisfied with this one. The most sensitive
limitation was the amount of built-in block RAM. Yes, it has some SDRAM, but the
nature of the most memory-consuming stuff (like FFT computation stages) requires
parallel access of multiple sub-blocks at the same clock cycle. There are only
to ways to overcome it: CPU-grade clock speed (unachievable) and use a chip with
more BRAM. Probably, it is possible to replace this 025Y with more capable chip
with pin-to-pin compatibility.

BTW, SDRAM chip seems to be dead by now. No response, even with old firmware
that used it successfully before. IDK why.

##### ADC #####

TI PCM1808

No surprises here. Minimalistic device with no program control

##### DAC #####

Here I had some problems. Probably, there was something wrong with the primary
DAC hardware piece (NXP UDA1334). Maybe there was a problem in analog circuit
design, or the part itself was malfunctioned. But there was an unpleasant
distortion on some volume level I would describe as moderate and higher.

Temporary solution was to attenuate the signal digitally 8 times in FPGA.
Of course, this made signal-to-noise ratio unacceptably low (because if we gain
it back we gain all the noises 8 times).

To fix it with acceptable result, I completely replaced the whole thing: Used
small Fiio D03K DAC which I put into the device as is. It just needed to write
another damn driver (SPDIF) to drive it, but it really works just fine. No
noise, etc.

This change broke the hardware relay which used to shortcut input to output when
the device is powered down (true bypass). Now it doesn't work. If you pull the
power cord, it breaks audio chain.

##### Knobs #####

8 knobs, linear scale. We use TI ADS7830 to read the values via I2C. 100 times
per second (seems more than enough). No surprises here.

##### Switches ######

Two foot switches (lacks hardware debouncing and often disobey). Side toggle
(currently used to receive tempo synchronization events). Side slide switch
(used to switch between line power and battery, now disabled)

### Delay ###


### Chorus ###


### Tremolo ###


### Frequency Machine ###


### Authors ###

 -- Dmitry Nekrasov <bluebag@yandex.ru>  Sun, 14 Apr 2024 11:36:12 +0300

 -- Ivan Lypar

### LICENSE ###

MIT
