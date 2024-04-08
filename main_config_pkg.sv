/*
 * MIT License
 *
 * Copyright (c) 2024 Dmitriy Nekrasov
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * ---------------------------------------------------------------------------------
 *
 * Main configuration. All static parameters should be controlled from here.
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:31 +0300
 */


package main_config;

parameter DATA_WIDTH_24_EN = 1;

parameter DATA_WIDTH = DATA_WIDTH_24_EN ? 24 : 16;

parameter INTERFACE_REMAP_EN = DATA_WIDTH_24_EN;

parameter STARTUP_MUSIC_EN = 0;

parameter NOISEGATE_THRESHOLD = 300;

//***********************************************************
// MEMORY

parameter NUM_MEMORY_MASTERS = 16;
parameter NUM_MEMORY_INTERFACES = DATA_WIDTH_24_EN ? NUM_MEMORY_MASTERS / 2 :
                                                     NUM_MEMORY_MASTERS;

//parameter MEM_ADDR_WIDTH = 22 - $clog2(NUM_MEMORY_MASTERS);
// Because only 1 sdram bank is available right now
parameter MEM_ADDR_WIDTH = 20 - $clog2(NUM_MEMORY_MASTERS);

// labels for external memory interface assignments
parameter DELAY_IF = 0;

//************************************************************
// Application core

// application core parts static on/off
parameter DUT_EN       = 0;
parameter NOISEGATE_EN = 0;
parameter CHORUS_EN    = 1;
parameter DELAY_EN     = 0;
parameter TREMOLO_EN   = 1;

// Labels for knob assignments
parameter  DEL_LEVEL  = 0;
parameter  REV_MIX    = 1;
parameter  DEL_TIME   = 2;
parameter  REV_DECAY  = 3;
parameter  CHORUS     = 4;
parameter  SWELL      = 5;
parameter  TREM_SPEED = 6;
parameter  TREM_DEPTH = 7;

endpackage
