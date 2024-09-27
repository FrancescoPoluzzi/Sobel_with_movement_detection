# You have to replace <ENTITY_PORT_NAME_xxx> with the name of the Clock port
# of your top entity
set_time_unit ns
set_decimal_places 3
derive_pll_clocks
derive_clock_uncertainty
create_clock -period 83.333 -waveform { 0 41.667 } clock12MHz -name clk1
create_clock -period 20.0 -waveform { 0 10.0 } clock50MHz -name clk2

