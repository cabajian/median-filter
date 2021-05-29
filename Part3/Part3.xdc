# ==== Clock input ====
set_property PACKAGE_PIN E3 [get_ports clk_100MHz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100MHz]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk_100MHz]

## ==== Push Button ====
set_property PACKAGE_PIN M18 [get_ports sys_rst]
set_property IOSTANDARD LVCMOS33 [get_ports sys_rst]

# ==== UART ====
set_property -dict {PACKAGE_PIN C4 IOSTANDARD LVCMOS33} [get_ports i_UART_RX]
set_property -dict {PACKAGE_PIN D4 IOSTANDARD LVCMOS33} [get_ports o_UART_TX]
