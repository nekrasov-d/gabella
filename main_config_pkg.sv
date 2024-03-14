/*
 * Copyright (C) 2021 Dmitriy Nekrasov
 *
 * This work is free. You can redistribute it and/or modify it under the
 * terms of the Do What The Fuck You Want To Public License, Version 2,
 * as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
 * for more details.
 *
 * Main configuration. All static parameters should be controlled from here.
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
