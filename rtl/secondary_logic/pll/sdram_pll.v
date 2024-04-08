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
 *  Altpll wrapper. Once it was MegaWizard autogenerated file, I did some
 *  refactoring so it's not that ugly
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:31 +0300
 */

module sdram_pll (
  input  inclk0,
  output c0,
  output locked
);

wire [4:0] sub_wire0;
wire sub_wire2;
wire [0:0] sub_wire5 = 1'h0;
wire [0:0] sub_wire1 = sub_wire0[0:0];
assign c0 = sub_wire1;
assign locked = sub_wire2;
wire sub_wire3 = inclk0;
wire [1:0] sub_wire4 = {sub_wire5, sub_wire3};

altpll altpll_component (
  .inclk              ( sub_wire4 ),
  .clk                ( sub_wire0 ),
  .locked             ( sub_wire2 ),
  .activeclock        (           ),
  .areset             ( 1'b0      ),
  .clkbad             (           ),
  .clkena             ( {6{1'b1}} ),
  .clkloss            (           ),
  .clkswitch          ( 1'b0      ),
  .configupdate       ( 1'b0      ),
  .enable0            (           ),
  .enable1            (           ),
  .extclk             (           ),
  .extclkena          ( {4{1'b1}} ),
  .fbin               ( 1'b1      ),
  .fbmimicbidir       (           ),
  .fbout              (           ),
  .fref               (           ),
  .icdrclk            (           ),
  .pfdena             ( 1'b1      ),
  .phasecounterselect ( {4{1'b1}} ),
  .phasedone          (           ),
  .phasestep          ( 1'b1      ),
  .phaseupdown        ( 1'b1      ),
  .pllena             ( 1'b1      ),
  .scanaclr           ( 1'b0      ),
  .scanclk            ( 1'b0      ),
  .scanclkena         ( 1'b1      ),
  .scandata           ( 1'b0      ),
  .scandataout        (           ),
  .scandone           (           ),
  .scanread           ( 1'b0      ),
  .scanwrite          ( 1'b0      ),
  .sclkout0           (           ),
  .sclkout1           (           ),
  .vcooverrange       (           ),
  .vcounderrange      (           )
);

defparam
  altpll_component.bandwidth_type          = "AUTO",
  altpll_component.clk0_divide_by          = 12,
  altpll_component.clk0_duty_cycle         = 50,
  altpll_component.clk0_multiply_by        = 33,
  altpll_component.clk0_phase_shift        = "0",
  altpll_component.compensate_clock        = "CLK0",
  altpll_component.inclk0_input_frequency  = 83333,
  altpll_component.intended_device_family  = "Cyclone 10 LP",
  altpll_component.lpm_hint                = "CBX_MODULE_PREFIX=sdram_pll",
  altpll_component.lpm_type                = "altpll",
  altpll_component.operation_mode          = "NORMAL",
  altpll_component.pll_type                = "AUTO",
  altpll_component.port_activeclock        = "PORT_UNUSED",
  altpll_component.port_areset             = "PORT_UNUSED",
  altpll_component.port_clkbad0            = "PORT_UNUSED",
  altpll_component.port_clkbad1            = "PORT_UNUSED",
  altpll_component.port_clkloss            = "PORT_UNUSED",
  altpll_component.port_clkswitch          = "PORT_UNUSED",
  altpll_component.port_configupdate       = "PORT_UNUSED",
  altpll_component.port_fbin               = "PORT_UNUSED",
  altpll_component.port_inclk0             = "PORT_USED",
  altpll_component.port_inclk1             = "PORT_UNUSED",
  altpll_component.port_locked             = "PORT_USED",
  altpll_component.port_pfdena             = "PORT_UNUSED",
  altpll_component.port_phasecounterselect = "PORT_UNUSED",
  altpll_component.port_phasedone          = "PORT_UNUSED",
  altpll_component.port_phasestep          = "PORT_UNUSED",
  altpll_component.port_phaseupdown        = "PORT_UNUSED",
  altpll_component.port_pllena             = "PORT_UNUSED",
  altpll_component.port_scanaclr           = "PORT_UNUSED",
  altpll_component.port_scanclk            = "PORT_UNUSED",
  altpll_component.port_scanclkena         = "PORT_UNUSED",
  altpll_component.port_scandata           = "PORT_UNUSED",
  altpll_component.port_scandataout        = "PORT_UNUSED",
  altpll_component.port_scandone           = "PORT_UNUSED",
  altpll_component.port_scanread           = "PORT_UNUSED",
  altpll_component.port_scanwrite          = "PORT_UNUSED",
  altpll_component.port_clk0               = "PORT_USED",
  altpll_component.port_clk1               = "PORT_UNUSED",
  altpll_component.port_clk2               = "PORT_UNUSED",
  altpll_component.port_clk3               = "PORT_UNUSED",
  altpll_component.port_clk4               = "PORT_UNUSED",
  altpll_component.port_clk5               = "PORT_UNUSED",
  altpll_component.port_clkena0            = "PORT_UNUSED",
  altpll_component.port_clkena1            = "PORT_UNUSED",
  altpll_component.port_clkena2            = "PORT_UNUSED",
  altpll_component.port_clkena3            = "PORT_UNUSED",
  altpll_component.port_clkena4            = "PORT_UNUSED",
  altpll_component.port_clkena5            = "PORT_UNUSED",
  altpll_component.port_extclk0            = "PORT_UNUSED",
  altpll_component.port_extclk1            = "PORT_UNUSED",
  altpll_component.port_extclk2            = "PORT_UNUSED",
  altpll_component.port_extclk3            = "PORT_UNUSED",
  altpll_component.self_reset_on_loss_lock = "OFF",
  altpll_component.width_clock             = 5;

endmodule

