# Constraints file for the Basys 3 FPGA development card

# Onboard crystal
set_property PACKAGE_PIN W5 [get_ports FPGA_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_CLK]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports FPGA_CLK]

# Reset (centre button)
set_property PACKAGE_PIN U18 [get_ports FPGA_nRESET]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_nRESET]

# Switches
set_property PACKAGE_PIN V17 [get_ports {SW[0]}]
set_property PACKAGE_PIN V16 [get_ports {SW[1]}]
set_property PACKAGE_PIN W16 [get_ports {SW[2]}]
set_property PACKAGE_PIN W17 [get_ports {SW[3]}]
set_property PACKAGE_PIN W15 [get_ports {SW[4]}]
set_property PACKAGE_PIN V15 [get_ports {SW[5]}]
set_property PACKAGE_PIN W14 [get_ports {SW[6]}]
set_property PACKAGE_PIN W13 [get_ports {SW[7]}]
set_property PACKAGE_PIN V2 [get_ports {SW[8]}]
set_property PACKAGE_PIN T3 [get_ports {SW[9]}]
set_property PACKAGE_PIN T2 [get_ports {SW[10]}]
set_property PACKAGE_PIN R3 [get_ports {SW[11]}]
set_property PACKAGE_PIN W2 [get_ports {SW[12]}]
set_property PACKAGE_PIN U1 [get_ports {SW[13]}]
set_property PACKAGE_PIN T1 [get_ports {SW[14]}]
set_property PACKAGE_PIN R2 [get_ports {SW[15]}]

set_property IOSTANDARD LVCMOS33 [get_ports {SW[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[15]}]

# LEDs
set_property PACKAGE_PIN U16 [get_ports {LED_DEBUG[0]}]
set_property PACKAGE_PIN E19 [get_ports {LED_DEBUG[1]}]
set_property PACKAGE_PIN U19 [get_ports {LED_DEBUG[2]}]
set_property PACKAGE_PIN V19 [get_ports {LED_DEBUG[3]}]
set_property PACKAGE_PIN W18 [get_ports {LED_DEBUG[4]}]
set_property PACKAGE_PIN U15 [get_ports {LED_DEBUG[5]}]
set_property PACKAGE_PIN U14 [get_ports {LED_DEBUG[6]}]
set_property PACKAGE_PIN V14 [get_ports {LED_DEBUG[7]}]
set_property PACKAGE_PIN V13 [get_ports {LED_DEBUG[8]}]
set_property PACKAGE_PIN V3 [get_ports {LED_DEBUG[9]}]
set_property PACKAGE_PIN W3 [get_ports {LED_DEBUG[10]}]
set_property PACKAGE_PIN U3 [get_ports {LED_DEBUG[11]}]
set_property PACKAGE_PIN P3 [get_ports {LED_DEBUG[12]}]
set_property PACKAGE_PIN N3 [get_ports {LED_DEBUG[13]}]
set_property PACKAGE_PIN P1 [get_ports {LED_DEBUG[14]}]
set_property PACKAGE_PIN L1 [get_ports {LED_DEBUG[15]}]

set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_DEBUG[15]}]

# Pmod Header JB - RGB Signals
set_property PACKAGE_PIN A14 [get_ports G1]
set_property PACKAGE_PIN A16 [get_ports B1]
set_property PACKAGE_PIN B15 [get_ports G2]
set_property PACKAGE_PIN B16 [get_ports B2]
set_property PACKAGE_PIN A15 [get_ports R1]
#set_property PACKAGE_PIN A17 [get_ports {  }]
set_property PACKAGE_PIN C15 [get_ports R2]
#set_property PACKAGE_PIN C16 [get_ports {  }]

set_property IOSTANDARD LVCMOS33 [get_ports R1]
set_property IOSTANDARD LVCMOS33 [get_ports R2]
set_property IOSTANDARD LVCMOS33 [get_ports G1]
set_property IOSTANDARD LVCMOS33 [get_ports G2]
set_property IOSTANDARD LVCMOS33 [get_ports B1]
set_property IOSTANDARD LVCMOS33 [get_ports B2]
#set_property IOSTANDARD LVCMOS33 [get_ports {  }]
#set_property IOSTANDARD LVCMOS33 [get_ports {  }]

# Pmod Header JC - Address and Control Signals
set_property PACKAGE_PIN K17 [get_ports B]
set_property PACKAGE_PIN M18 [get_ports D]
set_property PACKAGE_PIN N17 [get_ports LAT]
set_property PACKAGE_PIN P18 [get_ports OE]
set_property PACKAGE_PIN L17 [get_ports A]
set_property PACKAGE_PIN M19 [get_ports C]
set_property PACKAGE_PIN P17 [get_ports BCLK]
#set_property PACKAGE_PIN R18 [get_ports {  }]

set_property IOSTANDARD LVCMOS33 [get_ports A]
set_property IOSTANDARD LVCMOS33 [get_ports B]
set_property IOSTANDARD LVCMOS33 [get_ports C]
set_property IOSTANDARD LVCMOS33 [get_ports D]
set_property IOSTANDARD LVCMOS33 [get_ports BCLK]
set_property IOSTANDARD LVCMOS33 [get_ports LAT]
set_property IOSTANDARD LVCMOS33 [get_ports OE]
#set_property IOSTANDARD LVCMOS33 [get_ports {  }]

#USB-RS232 Interface
set_property PACKAGE_PIN B18 [get_ports UART_RX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_RX]
set_property PACKAGE_PIN A18 [get_ports UART_TX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX]
