/*
 * Copyright (C) 2021 Dmitriy Nekrasov
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * Main configuration. All static parameters should be controlled from here.
*/

package main_config;

parameter DATA_WIDTH_24_EN = 1;

parameter DATA_WIDTH = DATA_WIDTH_24_EN ? 24 : 16;

parameter INTERFACE_REMAP_EN = DATA_WIDTH_24_EN;

parameter SIN_GEN_ENABLE = 0;
parameter STARTUP_MUSIC_EN = 0;

parameter LIMITER = 4_000_000;

//***********************************************************
// MEMORY

parameter NUM_MEMORY_MASTERS = 16;
parameter NUM_MEMORY_INTERFACES = DATA_WIDTH_24_EN ? NUM_MEMORY_MASTERS / 2 :
                                                     NUM_MEMORY_MASTERS;

//parameter MEM_ADDR_WIDTH = 22 - $clog2(NUM_MEMORY_MASTERS);
parameter MEM_ADDR_WIDTH = 20 - $clog2(NUM_MEMORY_MASTERS);


//************************************************************
// Application core

// application core parts static on/off
parameter DEBUG_RECORDER_EN = 0;
parameter SWELL_EN          = 1;
parameter DRIVE_EN          = 1;
parameter CHORUS_EN         = 1;
parameter DELAY_EN          = 1;
parameter REVERB_EN         = 0;

// Labels for knob assignments
parameter  DEL_LEVEL = 0;
parameter  REV_MIX   = 1;
parameter  DEL_TIME  = 2;
parameter  REV_DECAY = 3;
parameter  CHORUS    = 4;
parameter  SWELL     = 5;
parameter  DRIVE     = 6;
parameter  UNUSED    = 7;


// labels for external memory interface assignments
parameter DELAY_IF = 0;


endpackage
