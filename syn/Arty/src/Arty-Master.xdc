## Pmod Header JA
#set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33 } [get_ports { ja[0] }];
#set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports RXD]
#set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports TXD]
#set_property -dict { PACKAGE_PIN D12   IOSTANDARD LVCMOS33 } [get_ports { ja[3] }];
#set_property -dict { PACKAGE_PIN D13   IOSTANDARD LVCMOS33 } [get_ports { ja[4] }];
#set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports { ja[5] }];
#set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33 } [get_ports { ja[6] }];
#set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { ja[7] }];

## Pmod Header JB
set_property -dict {PACKAGE_PIN E15 IOSTANDARD LVCMOS33} [get_ports PCK]
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVCMOS33} [get_ports PWRITE]
set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS33} [get_ports {PWD[0]}]
set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS33} [get_ports {PWD[1]}]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports PWAIT]
#set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports {  }];
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33} [get_ports {PRD[0]}]
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports {PRD[1]}]

