create_clock -name {clk_12} -period 83.333 -waveform { 0.000 41.666 } [get_ports {clk_12m_i}]

create_generated_clock -name sys_clk   -source [get_ports {clk_12m_i}] [get_pins {design_subsystems|sys_pll|altpll_component|auto_generated|pll1|clk[0]}]   -multiply_by 25   -divide_by 12
create_generated_clock -name i2s_clk   -source [get_ports {clk_12m_i}] [get_pins {design_subsystems|i2s_pll|altpll_component|auto_generated|pll1|clk[0]}]   -multiply_by 175  -divide_by 186
create_generated_clock -name sdram_clk -source [get_ports {clk_12m_i}] [get_pins {design_subsystems|sdram_pll|altpll_component|auto_generated|pll1|clk[0]}] -multiply_by 33   -divide_by 12

derive_pll_clocks
derive_clock_uncertainty

set_output_delay -clock i2s_clk -min 0.0  [get_ports i2s_bclk_o]
set_output_delay -clock i2s_clk -max 0.0  [get_ports i2s_bclk_o]
set_output_delay -clock i2s_clk -min 0.0  [get_ports i2s_lrclk_o]
set_output_delay -clock i2s_clk -max 0.0  [get_ports i2s_lrclk_o]

# Dumb but idk real delays
set_output_delay -clock sdram_clk -min 0.0 [get_ports a_o[*]]
set_output_delay -clock sdram_clk -max 0.0 [get_ports a_o[*]]
set_output_delay -clock sdram_clk -min 0.0 [get_ports bs_o[*]]
set_output_delay -clock sdram_clk -max 0.0 [get_ports bs_o[*]]
set_output_delay -clock sdram_clk -min 0.0 [get_ports dq_io[*]]
set_output_delay -clock sdram_clk -max 0.0 [get_ports dq_io[*]]
set_output_delay -clock sdram_clk -min 0.0 [get_ports dqm_o[*]]
set_output_delay -clock sdram_clk -max 0.0 [get_ports dqm_o[*]]
set_output_delay -clock sdram_clk -min 0.0 [get_ports cs_o]
set_output_delay -clock sdram_clk -max 0.0 [get_ports cs_o]
set_output_delay -clock sdram_clk -min 0.0 [get_ports ras_o]
set_output_delay -clock sdram_clk -max 0.0 [get_ports ras_o]
set_output_delay -clock sdram_clk -min 0.0 [get_ports cas_o]
set_output_delay -clock sdram_clk -max 0.0 [get_ports cas_o]
set_output_delay -clock sdram_clk -min 0.0 [get_ports we_o]
set_output_delay -clock sdram_clk -max 0.0 [get_ports we_o]
set_output_delay -clock sdram_clk -min 0.0 [get_ports cke_o]
set_output_delay -clock sdram_clk -max 0.0 [get_ports cke_o]
set_input_delay  -clock sdram_clk -min 0.0 [get_ports dq_io[*]]
set_input_delay  -clock sdram_clk -max 0.0 [get_ports dq_io[*]]

set_false_path -from {clk_12}    -to {sys_clk}
set_false_path -from {clk_12}    -to {sdram_clk}
set_false_path -from {clk_12}    -to {i2s_clk}

set_false_path -from {sys_clk}   -to {clk_12}
set_false_path -from {sys_clk}   -to {i2s_clk}
set_false_path -from {sys_clk}   -to {sdram_clk}

set_false_path -from {i2s_clk}   -to {sys_clk}
set_false_path -from {i2s_clk}   -to {sdram_clk}
set_false_path -from {i2s_clk}   -to {clk_12}

set_false_path -from {sdram_clk}   -to {sys_clk}
set_false_path -from {sdram_clk}   -to {i2s_clk}
set_false_path -from {sdram_clk}   -to {clk_12}

# CDC in board_memory.sv
#set_false_path -to {design_subsystems:design_subsystems|board_memory:board_memory|action_strobe_sdram_clk}

