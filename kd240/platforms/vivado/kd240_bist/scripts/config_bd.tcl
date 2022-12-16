# Copyright (C) 2022, Advanced Micro Devices, Inc.
# SPDX-License-Identifier: Apache-2.0

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: gate_driver
proc create_hier_cell_gate_driver { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_gate_driver() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir O gate_drive_phase_a
  create_bd_pin -dir O gate_drive_phase_b
  create_bd_pin -dir O gate_drive_phase_c
  create_bd_pin -dir O -from 0 -to 0 phase_lower
  create_bd_pin -dir O -from 0 -to 0 phase_upper
  create_bd_pin -dir I -type clk sys_clk
  create_bd_pin -dir I -type rst sys_rstn
  create_bd_pin -dir I -from 2 -to 0 ttc

  # Create instance: gate_driver_A, and set properties
  set gate_driver_A [ create_bd_cell -type ip -vlnv xilinx.com:user:gate_driver gate_driver_A ]

  # Create instance: gate_driver_B, and set properties
  set gate_driver_B [ create_bd_cell -type ip -vlnv xilinx.com:user:gate_driver gate_driver_B ]

  # Create instance: gate_driver_C, and set properties
  set gate_driver_C [ create_bd_cell -type ip -vlnv xilinx.com:user:gate_driver gate_driver_C ]

  # Create instance: xlslice_lower, and set properties
  set xlslice_lower [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_lower ]
  set_property CONFIG.DIN_WIDTH {3} $xlslice_lower


  # Create instance: xlslice_upper, and set properties
  set xlslice_upper [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_upper ]
  set_property -dict [list \
    CONFIG.DIN_FROM {1} \
    CONFIG.DIN_TO {1} \
    CONFIG.DIN_WIDTH {3} \
  ] $xlslice_upper


  # Create port connections
  connect_bd_net -net gate_driver_A_gate_drive [get_bd_pins gate_drive_phase_a] [get_bd_pins gate_driver_A/gate_drive]
  connect_bd_net -net gate_driver_B_gate_drive [get_bd_pins gate_drive_phase_b] [get_bd_pins gate_driver_B/gate_drive]
  connect_bd_net -net gate_driver_C_gate_drive [get_bd_pins gate_drive_phase_c] [get_bd_pins gate_driver_C/gate_drive]
  connect_bd_net -net xlslice_lower_Dout [get_bd_pins phase_upper] [get_bd_pins gate_driver_A/phase_lower] -boundary_type upper
  connect_bd_net -net xlslice_lower_Dout [get_bd_pins phase_upper] [get_bd_pins gate_driver_B/phase_lower] -boundary_type upper
  connect_bd_net -net xlslice_lower_Dout [get_bd_pins phase_upper] [get_bd_pins gate_driver_C/phase_lower] -boundary_type upper
  connect_bd_net -net xlslice_lower_Dout [get_bd_pins phase_upper] [get_bd_pins xlslice_lower/Dout] -boundary_type upper
  connect_bd_net -net xlslice_upper_Dout [get_bd_pins phase_lower] [get_bd_pins gate_driver_A/phase_upper] -boundary_type upper
  connect_bd_net -net xlslice_upper_Dout [get_bd_pins phase_lower] [get_bd_pins gate_driver_B/phase_upper] -boundary_type upper
  connect_bd_net -net xlslice_upper_Dout [get_bd_pins phase_lower] [get_bd_pins gate_driver_C/phase_upper] -boundary_type upper
  connect_bd_net -net xlslice_upper_Dout [get_bd_pins phase_lower] [get_bd_pins xlslice_upper/Dout] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_emio_ttc0_wave_o [get_bd_pins ttc] [get_bd_pins xlslice_lower/Din] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_emio_ttc0_wave_o [get_bd_pins ttc] [get_bd_pins xlslice_upper/Din] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins sys_clk] [get_bd_pins gate_driver_A/sys_clk] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins sys_clk] [get_bd_pins gate_driver_B/sys_clk] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins sys_clk] [get_bd_pins gate_driver_C/sys_clk] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins sys_rstn] [get_bd_pins gate_driver_A/sys_rstn] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins sys_rstn] [get_bd_pins gate_driver_B/sys_rstn] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins sys_rstn] [get_bd_pins gate_driver_C/sys_rstn] -boundary_type upper

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: ethernet_subsystem
proc create_hier_cell_ethernet_subsystem { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_ethernet_subsystem() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:mdio_rtl:1.0 gem1_mdio

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 gem1_rgmii

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:mdio_rtl:1.0 gem2_mdio

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 gem2_rgmii


  # Create pins
  create_bd_pin -dir O -from 7 -to 0 dout
  create_bd_pin -dir I -type rst ext_reset_in
  create_bd_pin -dir I -type clk gem1_clk_in
  create_bd_pin -dir O -from 0 -to 0 -type rst gem1_phy_rst_n
  create_bd_pin -dir I -type clk gem2_clk_in
  create_bd_pin -dir O -from 0 -to 0 -type rst gem2_phy_rst_n
  create_bd_pin -dir I -type clk m_axi_mm2s_aclk

  # Create instance: axi_dma_0, and set properties
  set axi_dma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_dma_0 ]

  # Create instance: axi_dma_1, and set properties
  set axi_dma_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_dma_1 ]

  # Create instance: axi_ethernet_0, and set properties
  set axi_ethernet_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet axi_ethernet_0 ]
  set_property -dict [list \
    CONFIG.PHY_TYPE {RGMII} \
    CONFIG.SupportLevel {1} \
  ] $axi_ethernet_0


  # Create instance: axi_ethernet_1, and set properties
  set axi_ethernet_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet axi_ethernet_1 ]
  set_property -dict [list \
    CONFIG.PHY_TYPE {RGMII} \
    CONFIG.SupportLevel {0} \
  ] $axi_ethernet_1


  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_0 ]
  set_property CONFIG.NUM_MI {4} $axi_interconnect_0


  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smc ]
  set_property CONFIG.NUM_SI {6} $axi_smc


  # Create instance: clk_wiz, and set properties
  set clk_wiz [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz ]
  set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {125} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {333.33333} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.NUM_OUT_CLKS {2} \
    CONFIG.PRIM_IN_FREQ {25} \
    CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.USE_LOCKED {false} \
    CONFIG.USE_RESET {false} \
  ] $clk_wiz


  # Create instance: clk_wiz_1, and set properties
  set clk_wiz_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_1 ]
  set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {125} \
    CONFIG.PRIM_IN_FREQ {25} \
    CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.USE_LOCKED {false} \
    CONFIG.USE_RESET {false} \
  ] $clk_wiz_1


  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0 ]
  set_property CONFIG.NUM_PORTS {8} $xlconcat_0


  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXIS_CNTRL [get_bd_intf_pins axi_dma_0/M_AXIS_CNTRL] [get_bd_intf_pins axi_ethernet_0/s_axis_txc]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXIS_MM2S [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S] [get_bd_intf_pins axi_ethernet_0/s_axis_txd]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_MM2S [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] [get_bd_intf_pins axi_smc/S00_AXI]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_S2MM [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] [get_bd_intf_pins axi_smc/S01_AXI]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_SG [get_bd_intf_pins axi_dma_0/M_AXI_SG] [get_bd_intf_pins axi_smc/S02_AXI]
  connect_bd_intf_net -intf_net axi_dma_1_M_AXIS_CNTRL [get_bd_intf_pins axi_dma_1/M_AXIS_CNTRL] [get_bd_intf_pins axi_ethernet_1/s_axis_txc]
  connect_bd_intf_net -intf_net axi_dma_1_M_AXIS_MM2S [get_bd_intf_pins axi_dma_1/M_AXIS_MM2S] [get_bd_intf_pins axi_ethernet_1/s_axis_txd]
  connect_bd_intf_net -intf_net axi_dma_1_M_AXI_MM2S [get_bd_intf_pins axi_dma_1/M_AXI_MM2S] [get_bd_intf_pins axi_smc/S03_AXI]
  connect_bd_intf_net -intf_net axi_dma_1_M_AXI_S2MM [get_bd_intf_pins axi_dma_1/M_AXI_S2MM] [get_bd_intf_pins axi_smc/S04_AXI]
  connect_bd_intf_net -intf_net axi_dma_1_M_AXI_SG [get_bd_intf_pins axi_dma_1/M_AXI_SG] [get_bd_intf_pins axi_smc/S05_AXI]
  connect_bd_intf_net -intf_net axi_ethernet_0_m_axis_rxd [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM] [get_bd_intf_pins axi_ethernet_0/m_axis_rxd]
  connect_bd_intf_net -intf_net axi_ethernet_0_m_axis_rxs [get_bd_intf_pins axi_dma_0/S_AXIS_STS] [get_bd_intf_pins axi_ethernet_0/m_axis_rxs]
  connect_bd_intf_net -intf_net axi_ethernet_0_mdio [get_bd_intf_pins gem2_mdio] [get_bd_intf_pins axi_ethernet_0/mdio]
  connect_bd_intf_net -intf_net axi_ethernet_0_rgmii [get_bd_intf_pins gem2_rgmii] [get_bd_intf_pins axi_ethernet_0/rgmii]
  connect_bd_intf_net -intf_net axi_ethernet_1_m_axis_rxd [get_bd_intf_pins axi_dma_1/S_AXIS_S2MM] [get_bd_intf_pins axi_ethernet_1/m_axis_rxd]
  connect_bd_intf_net -intf_net axi_ethernet_1_m_axis_rxs [get_bd_intf_pins axi_dma_1/S_AXIS_STS] [get_bd_intf_pins axi_ethernet_1/m_axis_rxs]
  connect_bd_intf_net -intf_net axi_ethernet_1_mdio [get_bd_intf_pins gem1_mdio] [get_bd_intf_pins axi_ethernet_1/mdio]
  connect_bd_intf_net -intf_net axi_ethernet_1_rgmii [get_bd_intf_pins gem1_rgmii] [get_bd_intf_pins axi_ethernet_1/rgmii]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_dma_0/S_AXI_LITE] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_ethernet_0/s_axi] [get_bd_intf_pins axi_interconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins axi_dma_1/S_AXI_LITE] [get_bd_intf_pins axi_interconnect_0/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M03_AXI [get_bd_intf_pins axi_ethernet_1/s_axi] [get_bd_intf_pins axi_interconnect_0/M03_AXI]
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins M00_AXI] [get_bd_intf_pins axi_smc/M00_AXI]

  # Create port connections
  connect_bd_net -net axi_dma_0_mm2s_cntrl_reset_out_n [get_bd_pins axi_dma_0/mm2s_cntrl_reset_out_n] [get_bd_pins axi_ethernet_0/axi_txc_arstn]
  connect_bd_net -net axi_dma_0_mm2s_introut [get_bd_pins axi_dma_0/mm2s_introut] [get_bd_pins xlconcat_0/In2]
  connect_bd_net -net axi_dma_0_mm2s_prmry_reset_out_n [get_bd_pins axi_dma_0/mm2s_prmry_reset_out_n] [get_bd_pins axi_ethernet_0/axi_txd_arstn]
  connect_bd_net -net axi_dma_0_s2mm_introut [get_bd_pins axi_dma_0/s2mm_introut] [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net axi_dma_0_s2mm_prmry_reset_out_n [get_bd_pins axi_dma_0/s2mm_prmry_reset_out_n] [get_bd_pins axi_ethernet_0/axi_rxd_arstn]
  connect_bd_net -net axi_dma_0_s2mm_sts_reset_out_n [get_bd_pins axi_dma_0/s2mm_sts_reset_out_n] [get_bd_pins axi_ethernet_0/axi_rxs_arstn]
  connect_bd_net -net axi_dma_1_mm2s_cntrl_reset_out_n [get_bd_pins axi_dma_1/mm2s_cntrl_reset_out_n] [get_bd_pins axi_ethernet_1/axi_txc_arstn]
  connect_bd_net -net axi_dma_1_mm2s_introut [get_bd_pins axi_dma_1/mm2s_introut] [get_bd_pins xlconcat_0/In4]
  connect_bd_net -net axi_dma_1_mm2s_prmry_reset_out_n [get_bd_pins axi_dma_1/mm2s_prmry_reset_out_n] [get_bd_pins axi_ethernet_1/axi_txd_arstn]
  connect_bd_net -net axi_dma_1_s2mm_introut [get_bd_pins axi_dma_1/s2mm_introut] [get_bd_pins xlconcat_0/In5]
  connect_bd_net -net axi_dma_1_s2mm_prmry_reset_out_n [get_bd_pins axi_dma_1/s2mm_prmry_reset_out_n] [get_bd_pins axi_ethernet_1/axi_rxd_arstn]
  connect_bd_net -net axi_dma_1_s2mm_sts_reset_out_n [get_bd_pins axi_dma_1/s2mm_sts_reset_out_n] [get_bd_pins axi_ethernet_1/axi_rxs_arstn]
  connect_bd_net -net axi_ethernet_0_interrupt [get_bd_pins axi_ethernet_0/interrupt] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net axi_ethernet_0_mac_irq [get_bd_pins axi_ethernet_0/mac_irq] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net axi_ethernet_0_phy_rst_n [get_bd_pins gem2_phy_rst_n] [get_bd_pins axi_ethernet_0/phy_rst_n]
  connect_bd_net -net axi_ethernet_1_interrupt [get_bd_pins axi_ethernet_1/interrupt] [get_bd_pins xlconcat_0/In7]
  connect_bd_net -net axi_ethernet_1_mac_irq [get_bd_pins axi_ethernet_1/mac_irq] [get_bd_pins xlconcat_0/In6]
  connect_bd_net -net axi_ethernet_1_phy_rst_n [get_bd_pins gem1_phy_rst_n] [get_bd_pins axi_ethernet_1/phy_rst_n]
  connect_bd_net -net clk_100MHz_1 [get_bd_pins gem2_clk_in] [get_bd_pins clk_wiz/clk_in1]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_dma_0/m_axi_mm2s_aclk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_dma_0/m_axi_s2mm_aclk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_dma_0/m_axi_sg_aclk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_dma_0/s_axi_lite_aclk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_dma_1/m_axi_mm2s_aclk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_dma_1/m_axi_s2mm_aclk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_dma_1/m_axi_sg_aclk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_dma_1/s_axi_lite_aclk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_ethernet_0/axis_clk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_ethernet_0/s_axi_lite_clk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_ethernet_1/axis_clk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_ethernet_1/s_axi_lite_clk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_interconnect_0/ACLK] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_interconnect_0/M00_ACLK] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_interconnect_0/M01_ACLK] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_interconnect_0/M02_ACLK] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_interconnect_0/M03_ACLK] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_interconnect_0/S00_ACLK] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins axi_smc/aclk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins m_axi_mm2s_aclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] -boundary_type upper
  connect_bd_net -net clk_wiz_1_clk_out1 [get_bd_pins axi_ethernet_1/gtx_clk] [get_bd_pins clk_wiz_1/clk_out1]
  connect_bd_net -net clk_wiz_clk_out1 [get_bd_pins axi_ethernet_0/gtx_clk] [get_bd_pins clk_wiz/clk_out1]
  connect_bd_net -net clk_wiz_clk_out2 [get_bd_pins axi_ethernet_0/ref_clk] [get_bd_pins clk_wiz/clk_out2]
  connect_bd_net -net gem1_clk_in_1 [get_bd_pins gem1_clk_in] [get_bd_pins clk_wiz_1/clk_in1]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axi_dma_1/axi_resetn] -boundary_type upper
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axi_ethernet_0/s_axi_lite_resetn] -boundary_type upper
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axi_ethernet_1/s_axi_lite_resetn] -boundary_type upper
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axi_interconnect_0/M00_ARESETN] -boundary_type upper
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axi_interconnect_0/M01_ARESETN] -boundary_type upper
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axi_interconnect_0/M02_ARESETN] -boundary_type upper
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axi_interconnect_0/M03_ARESETN] -boundary_type upper
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axi_interconnect_0/S00_ARESETN] -boundary_type upper
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axi_smc/aresetn] -boundary_type upper
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn] -boundary_type upper
  connect_bd_net -net xlconcat_0_dout [get_bd_pins dout] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins ext_reset_in] [get_bd_pins proc_sys_reset_0/ext_reset_in]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: ADC
proc create_hier_cell_ADC { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_ADC() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 L0_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 L1_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 L2_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI


  # Create pins
  create_bd_pin -dir I -type clk CLK
  create_bd_pin -dir O -from 7 -to 0 CSn
  create_bd_pin -dir I -type rst RESETn
  create_bd_pin -dir I -type clk SCLK
  create_bd_pin -dir I -type rst SCLK_RESETn
  create_bd_pin -dir I -from 7 -to 0 SDATA
  create_bd_pin -dir I UPDATE
  create_bd_pin -dir O -from 0 -to 0 dc_link_oc_err
  create_bd_pin -dir O -from 0 -to 0 dc_link_ov_err
  create_bd_pin -dir O -type intr interrupt
  create_bd_pin -dir O -from 0 -to 0 phase_a_oc_err
  create_bd_pin -dir O -from 0 -to 0 phase_b_oc_err
  create_bd_pin -dir O -from 0 -to 0 phase_c_oc_err

  # Create instance: adc_hub_0, and set properties
  set adc_hub_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:adc_hub adc_hub_0 ]
  set_property -dict [list \
    CONFIG.L0_TYPE {VOLTAGE} \
    CONFIG.L1_TYPE {CURRENT} \
    CONFIG.L2_TYPE {VOLTAGE} \
    CONFIG.L3_TYPE {CURRENT} \
    CONFIG.L5_TYPE {CURRENT} \
    CONFIG.L7_TYPE {CURRENT} \
    CONFIG.NUM_CHANNELS {8} \
  ] $adc_hub_0


  # Create instance: adc_if, and set properties
  set adc_if [ create_bd_cell -type ip -vlnv xilinx.com:user:adc7352_if adc_if ]
  set_property CONFIG.NUM_CHANNELS {8} $adc_if


  # Create instance: xlslice_oc_err_0, and set properties
  set xlslice_oc_err_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_oc_err_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {0} \
    CONFIG.DIN_TO {0} \
    CONFIG.DIN_WIDTH {8} \
    CONFIG.DOUT_WIDTH {1} \
  ] $xlslice_oc_err_0


  # Create instance: xlslice_oc_err_1, and set properties
  set xlslice_oc_err_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_oc_err_1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {1} \
    CONFIG.DIN_TO {1} \
    CONFIG.DIN_WIDTH {8} \
    CONFIG.DOUT_WIDTH {1} \
  ] $xlslice_oc_err_1


  # Create instance: xlslice_oc_err_2, and set properties
  set xlslice_oc_err_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_oc_err_2 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {2} \
    CONFIG.DIN_TO {2} \
    CONFIG.DIN_WIDTH {8} \
  ] $xlslice_oc_err_2


  # Create instance: xlslice_oc_err_3, and set properties
  set xlslice_oc_err_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_oc_err_3 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {3} \
    CONFIG.DIN_TO {3} \
    CONFIG.DIN_WIDTH {8} \
    CONFIG.DOUT_WIDTH {1} \
  ] $xlslice_oc_err_3


  # Create instance: xlslice_oc_err_7, and set properties
  set xlslice_oc_err_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_oc_err_7 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {7} \
    CONFIG.DIN_TO {7} \
    CONFIG.DIN_WIDTH {8} \
    CONFIG.DOUT_WIDTH {1} \
  ] $xlslice_oc_err_7


  # Create interface connections
  connect_bd_intf_net -intf_net adc_hub_0_L1_AXIS [get_bd_intf_pins L1_AXIS] [get_bd_intf_pins adc_hub_0/L1_AXIS]
  connect_bd_intf_net -intf_net adc_hub_0_L2_AXIS [get_bd_intf_pins L2_AXIS] [get_bd_intf_pins adc_hub_0/L2_AXIS]
  connect_bd_intf_net -intf_net adc_hub_1_L0_AXIS [get_bd_intf_pins L0_AXIS] [get_bd_intf_pins adc_hub_0/L0_AXIS]
  connect_bd_intf_net -intf_net adc_if_phase_a_b_i_L0_ADC [get_bd_intf_pins adc_hub_0/L0_ADC] [get_bd_intf_pins adc_if/L0_ADC]
  connect_bd_intf_net -intf_net adc_if_phase_a_b_i_L1_ADC [get_bd_intf_pins adc_hub_0/L1_ADC] [get_bd_intf_pins adc_if/L1_ADC]
  connect_bd_intf_net -intf_net adc_if_phase_a_b_i_L2_ADC [get_bd_intf_pins adc_hub_0/L2_ADC] [get_bd_intf_pins adc_if/L2_ADC]
  connect_bd_intf_net -intf_net adc_if_phase_a_b_i_L3_ADC [get_bd_intf_pins adc_hub_0/L3_ADC] [get_bd_intf_pins adc_if/L3_ADC]
  connect_bd_intf_net -intf_net adc_if_phase_a_b_i_L4_ADC [get_bd_intf_pins adc_hub_0/L4_ADC] [get_bd_intf_pins adc_if/L4_ADC]
  connect_bd_intf_net -intf_net adc_if_phase_a_b_i_L5_ADC [get_bd_intf_pins adc_hub_0/L5_ADC] [get_bd_intf_pins adc_if/L5_ADC]
  connect_bd_intf_net -intf_net adc_if_phase_a_b_i_L6_ADC [get_bd_intf_pins adc_hub_0/L6_ADC] [get_bd_intf_pins adc_if/L6_ADC]
  connect_bd_intf_net -intf_net adc_if_phase_a_b_i_L7_ADC [get_bd_intf_pins adc_hub_0/L7_ADC] [get_bd_intf_pins adc_if/L7_ADC]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins adc_hub_0/S_AXI]

  # Create port connections
  connect_bd_net -net SDATA_0_1 [get_bd_pins SDATA] [get_bd_pins adc_if/SDATA]
  connect_bd_net -net adc_hub_1_interrupt [get_bd_pins interrupt] [get_bd_pins adc_hub_0/interrupt]
  connect_bd_net -net adc_hub_1_over_fault [get_bd_pins adc_hub_0/over_fault] [get_bd_pins xlslice_oc_err_0/Din] -boundary_type upper
  connect_bd_net -net adc_hub_1_over_fault [get_bd_pins adc_hub_0/over_fault] [get_bd_pins xlslice_oc_err_1/Din] -boundary_type upper
  connect_bd_net -net adc_hub_1_over_fault [get_bd_pins adc_hub_0/over_fault] [get_bd_pins xlslice_oc_err_2/Din] -boundary_type upper
  connect_bd_net -net adc_hub_1_over_fault [get_bd_pins adc_hub_0/over_fault] [get_bd_pins xlslice_oc_err_3/Din] -boundary_type upper
  connect_bd_net -net adc_hub_1_over_fault [get_bd_pins adc_hub_0/over_fault] [get_bd_pins xlslice_oc_err_7/Din] -boundary_type upper
  connect_bd_net -net adc_if_0_CSn [get_bd_pins CSn] [get_bd_pins adc_if/CSn]
  connect_bd_net -net clk_wiz_0_clk_out_20M1 [get_bd_pins SCLK] [get_bd_pins adc_if/SCLK]
  connect_bd_net -net phase_a_i_Dout3 [get_bd_pins phase_b_oc_err] [get_bd_pins xlslice_oc_err_1/Dout]
  connect_bd_net -net phase_b_i_Dout3 [get_bd_pins phase_a_oc_err] [get_bd_pins xlslice_oc_err_0/Dout]
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins SCLK_RESETn] [get_bd_pins adc_if/SCLK_RESETn]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins UPDATE] [get_bd_pins adc_if/UPDATE]
  connect_bd_net -net xlslice_oc_err_2_Dout [get_bd_pins phase_c_oc_err] [get_bd_pins xlslice_oc_err_2/Dout]
  connect_bd_net -net xlslice_oc_err_3_Dout [get_bd_pins dc_link_oc_err] [get_bd_pins xlslice_oc_err_3/Dout]
  connect_bd_net -net xlslice_oc_err_4_Dout [get_bd_pins dc_link_ov_err] [get_bd_pins xlslice_oc_err_7/Dout]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins CLK] [get_bd_pins adc_hub_0/S_AXI_ACLK] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins CLK] [get_bd_pins adc_if/CLK] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins RESETn] [get_bd_pins adc_hub_0/S_AXI_ARESETN] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins RESETn] [get_bd_pins adc_if/RESETn] -boundary_type upper

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set GPIO_IN [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_IN ]

  set GPIO_OUT [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_OUT ]

  set gem1_mdio [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_rtl:1.0 gem1_mdio ]

  set gem1_rgmii [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 gem1_rgmii ]

  set gem2_mdio [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_rtl:1.0 gem2_mdio ]

  set gem2_rgmii [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 gem2_rgmii ]


  # Create ports
  set TQ_CSn [ create_bd_port -dir O -from 0 -to 0 TQ_CSn ]
  set TQ_SCLK [ create_bd_port -dir O TQ_SCLK ]
  set TQ_SDI [ create_bd_port -dir O TQ_SDI ]
  set TQ_SDO [ create_bd_port -dir I TQ_SDO ]
  set brake_cntrl [ create_bd_port -dir O -from 0 -to 0 brake_cntrl ]
  set dc_link_adc_cs_n [ create_bd_port -dir O -from 0 -to 0 dc_link_adc_cs_n ]
  set dc_link_adc_sclk [ create_bd_port -dir O dc_link_adc_sclk ]
  set dc_link_data_i [ create_bd_port -dir I dc_link_data_i ]
  set dc_link_data_v [ create_bd_port -dir I dc_link_data_v ]
  set fan_en_b [ create_bd_port -dir O -from 0 -to 0 fan_en_b ]
  set gate_drive_en [ create_bd_port -dir O -from 0 -to 0 gate_drive_en ]
  set gate_drive_phase_a [ create_bd_port -dir O gate_drive_phase_a ]
  set gate_drive_phase_b [ create_bd_port -dir O gate_drive_phase_b ]
  set gate_drive_phase_c [ create_bd_port -dir O gate_drive_phase_c ]
  set gem1_clk_in [ create_bd_port -dir I -type clk -freq_hz 25000000 gem1_clk_in ]
  set gem1_phy_rst_n [ create_bd_port -dir O -from 0 -to 0 -type rst gem1_phy_rst_n ]
  set gem2_clk_in [ create_bd_port -dir I -type clk -freq_hz 25000000 gem2_clk_in ]
  set gem2_phy_rst_n [ create_bd_port -dir O -from 0 -to 0 -type rst gem2_phy_rst_n ]
  set motor_adc_cs_n [ create_bd_port -dir O -from 0 -to 0 motor_adc_cs_n ]
  set motor_adc_sclk [ create_bd_port -dir O motor_adc_sclk ]
  set motor_pa_data_i [ create_bd_port -dir I motor_pa_data_i ]
  set motor_pa_data_v [ create_bd_port -dir I motor_pa_data_v ]
  set motor_pb_data_i [ create_bd_port -dir I motor_pb_data_i ]
  set motor_pb_data_v [ create_bd_port -dir I motor_pb_data_v ]
  set motor_pc_data_i [ create_bd_port -dir I motor_pc_data_i ]
  set motor_pc_data_v [ create_bd_port -dir I motor_pc_data_v ]
  set one_wire [ create_bd_port -dir O -from 0 -to 0 one_wire ]
  set qei_se_A [ create_bd_port -dir I qei_se_A ]
  set qei_se_B [ create_bd_port -dir I qei_se_B ]
  set qei_se_I [ create_bd_port -dir I qei_se_I ]

  # Create instance: ADC
  create_hier_cell_ADC [current_bd_instance .] ADC


  # Create instance: axi_gpio_pmod, and set properties
  set axi_gpio_pmod [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_pmod ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {0} \
    CONFIG.C_ALL_INPUTS_2 {1} \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_GPIO2_WIDTH {4} \
    CONFIG.C_GPIO_WIDTH {4} \
    CONFIG.C_IS_DUAL {1} \
  ] $axi_gpio_pmod

  # Create instance: axi_interconnect_cntrl, and set properties
  set axi_interconnect_cntrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_cntrl ]
  set_property CONFIG.NUM_MI {4} $axi_interconnect_cntrl


  # Create instance: axi_quad_spi_0, and set properties
  set axi_quad_spi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi axi_quad_spi_0 ]
  set_property -dict [list \
    CONFIG.C_SCK_RATIO {16} \
    CONFIG.C_SPI_MODE {0} \
    CONFIG.QSPI_BOARD_INTERFACE {Custom} \
  ] $axi_quad_spi_0

  # Create instance: ethernet_subsystem
  create_hier_cell_ethernet_subsystem [current_bd_instance .] ethernet_subsystem

  # Create instance: gate_driver
  create_hier_cell_gate_driver [current_bd_instance .] gate_driver

  # Create instance: ila_enc_qei, and set properties
  set ila_enc_qei [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila ila_enc_qei ]
  set_property -dict [list \
    CONFIG.C_MON_TYPE {NATIVE} \
    CONFIG.C_NUM_OF_PROBES {9} \
  ] $ila_enc_qei


  # Create instance: ila_gate_driver, and set properties
  set ila_gate_driver [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila ila_gate_driver ]
  set_property -dict [list \
    CONFIG.C_MON_TYPE {NATIVE} \
    CONFIG.C_NUM_OF_PROBES {6} \
  ] $ila_gate_driver


  # Create instance: hls_qei_top_0, and set properties
  set hls_qei_top_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:hls_qei_top hls_qei_top_0 ]

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]

  # Create instance: proc_sys_reset_1, and set properties
  set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_1 ]

  # Create instance: xlconcat_1, and set properties
  set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_1 ]
  set_property CONFIG.NUM_PORTS {8} $xlconcat_1


  # Create instance: xlconcat_int, and set properties
  set xlconcat_int [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_int ]
  set_property CONFIG.NUM_PORTS {2} $xlconcat_int


  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_1 ]

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_0 ]
  set_property CONFIG.DIN_WIDTH {8} $xlslice_0


  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {7} \
    CONFIG.DIN_TO {7} \
    CONFIG.DIN_WIDTH {8} \
  ] $xlslice_1


  # Create instance: xlslice_fan, and set properties
  set xlslice_fan [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_fan ]
  set_property -dict [list \
    CONFIG.DIN_FROM {2} \
    CONFIG.DIN_TO {2} \
    CONFIG.DIN_WIDTH {3} \
  ] $xlslice_fan


  # Create instance: xlslice_gpio_0, and set properties
  set xlslice_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_gpio_0 ]
  set_property CONFIG.DIN_WIDTH {94} $xlslice_gpio_0


  # Create instance: xlslice_gpio_1, and set properties
  set xlslice_gpio_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_gpio_1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {1} \
    CONFIG.DIN_TO {1} \
    CONFIG.DIN_WIDTH {94} \
  ] $xlslice_gpio_1


  # Create instance: xlslice_gpio_2, and set properties
  set xlslice_gpio_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_gpio_2 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {2} \
    CONFIG.DIN_TO {2} \
    CONFIG.DIN_WIDTH {94} \
  ] $xlslice_gpio_2

  # Create instance: zynq_ultra_ps_e_0, and set properties
  set zynq_ultra_ps_e_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0 ]
  apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]
  set_property -dict [ list \
   CONFIG.PSU__USE__IRQ0 {1} \
   CONFIG.PSU__USE__IRQ1 {1} \
   CONFIG.PSU__NUM_FABRIC_RESETS {2} \
   CONFIG.PSU__USE__M_AXI_GP0 {1} \
   CONFIG.PSU__USE__M_AXI_GP1 {0} \
   CONFIG.PSU__USE__M_AXI_GP2 {1} \
   CONFIG.PSU__USE__S_AXI_GP2 {1} \
   #CONFIG.PSU__USE__S_AXI_GP3 {1} \
   CONFIG.PSU__MAXIGP0__DATA_WIDTH {32} \
   CONFIG.PSU__MAXIGP2__DATA_WIDTH {32} \
   CONFIG.PSU__SAXIGP2__DATA_WIDTH {128} \
   #CONFIG.PSU__SAXIGP3__DATA_WIDTH {128} \
   CONFIG.PSU__FPGA_PL1_ENABLE {1} \
   CONFIG.PSU__CRL_APB__PL1_REF_CTRL__FREQMHZ {20} \
   CONFIG.PSU__GPIO_EMIO__PERIPHERAL__ENABLE {1}  \
   CONFIG.PSU__TTC0__WAVEOUT__ENABLE {1} \
   CONFIG.PSU__TTC0__WAVEOUT__IO {EMIO} \

 ] $zynq_ultra_ps_e_0

  # Create interface connections
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_M_AXI_HPM0_LPD [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_LPD] [get_bd_intf_pins ethernet_subsystem/S00_AXI]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports GPIO_OUT] [get_bd_intf_pins axi_gpio_pmod/GPIO]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO2 [get_bd_intf_ports GPIO_IN] [get_bd_intf_pins axi_gpio_pmod/GPIO2]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins ADC/S_AXI] [get_bd_intf_pins axi_interconnect_cntrl/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_cntrl_M01_AXI [get_bd_intf_pins axi_interconnect_cntrl/M01_AXI] [get_bd_intf_pins hls_qei_top_0/s_axi_qei_args]
  connect_bd_intf_net -intf_net axi_interconnect_cntrl_M02_AXI [get_bd_intf_pins axi_gpio_pmod/S_AXI] [get_bd_intf_pins axi_interconnect_cntrl/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_cntrl_M03_AXI [get_bd_intf_pins axi_interconnect_cntrl/M03_AXI] [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
  connect_bd_intf_net -intf_net ethernet_subsystem_M00_AXI [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP0_FPD] [get_bd_intf_pins ethernet_subsystem/M00_AXI]
  connect_bd_intf_net -intf_net ethernet_subsystem_gem2_mdio [get_bd_intf_ports gem1_mdio] [get_bd_intf_pins ethernet_subsystem/gem1_mdio]
  connect_bd_intf_net -intf_net ethernet_subsystem_gem2_rgmii [get_bd_intf_ports gem1_rgmii] [get_bd_intf_pins ethernet_subsystem/gem1_rgmii]
  connect_bd_intf_net -intf_net ethernet_subsystem_gem3_mdio [get_bd_intf_ports gem2_mdio] [get_bd_intf_pins ethernet_subsystem/gem2_mdio]
  connect_bd_intf_net -intf_net ethernet_subsystem_gem3_rgmii [get_bd_intf_ports gem2_rgmii] [get_bd_intf_pins ethernet_subsystem/gem2_rgmii]
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_M_AXI_HPM0_FPD [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD] [get_bd_intf_pins axi_interconnect_cntrl/S00_AXI]

  # Create port connections
  connect_bd_net -net ADC_CSn [get_bd_pins ADC/CSn] [get_bd_pins xlslice_0/Din] -boundary_type upper
  connect_bd_net -net ADC_CSn [get_bd_pins ADC/CSn] [get_bd_pins xlslice_1/Din] -boundary_type upper
  connect_bd_net -net ARESETN_1 [get_bd_pins axi_interconnect_cntrl/ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net A_0_1 [get_bd_ports qei_se_A] [get_bd_pins ila_enc_qei/probe4] -boundary_type upper
  connect_bd_net -net A_0_1 [get_bd_ports qei_se_A] [get_bd_pins hls_qei_top_0/qei_A_dout] -boundary_type upper
  connect_bd_net -net B_0_1 [get_bd_ports qei_se_B] [get_bd_pins ila_enc_qei/probe5] -boundary_type upper
  connect_bd_net -net B_0_1 [get_bd_ports qei_se_B] [get_bd_pins hls_qei_top_0/qei_B_dout] -boundary_type upper
  connect_bd_net -net I_0_1 [get_bd_ports qei_se_I] [get_bd_pins ila_enc_qei/probe6] -boundary_type upper
  connect_bd_net -net I_0_1 [get_bd_ports qei_se_I] [get_bd_pins hls_qei_top_0/qei_I_dout] -boundary_type upper
  connect_bd_net -net TQ_SDO_1 [get_bd_ports TQ_SDO] [get_bd_pins axi_quad_spi_0/io0_i]
  connect_bd_net -net adc_hub_1_interrupt [get_bd_pins ADC/interrupt] [get_bd_pins xlconcat_int/In0]
  connect_bd_net -net axi_quad_spi_0_io0_o [get_bd_ports TQ_SDI] [get_bd_pins axi_quad_spi_0/io0_o]
  connect_bd_net -net axi_quad_spi_0_ip2intc_irpt [get_bd_pins axi_quad_spi_0/ip2intc_irpt] [get_bd_pins xlconcat_int/In1]
  connect_bd_net -net axi_quad_spi_0_sck_o [get_bd_ports TQ_SCLK] [get_bd_pins axi_quad_spi_0/sck_o]
  connect_bd_net -net axi_quad_spi_0_ss_o [get_bd_ports TQ_CSn] [get_bd_pins axi_quad_spi_0/ss_o]
  connect_bd_net -net clk_wiz_0_clk_out_20M1 [get_bd_ports dc_link_adc_sclk] [get_bd_ports motor_adc_sclk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out_20M1 [get_bd_ports dc_link_adc_sclk] [get_bd_pins ADC/SCLK] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out_20M1 [get_bd_ports dc_link_adc_sclk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk1] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out_20M1 [get_bd_ports dc_link_adc_sclk] [get_bd_pins proc_sys_reset_1/slowest_sync_clk] -boundary_type upper
  connect_bd_net -net dc_link_data_a_1 [get_bd_ports dc_link_data_v] [get_bd_pins xlconcat_1/In6]
  connect_bd_net -net dc_link_data_b_1 [get_bd_ports dc_link_data_i] [get_bd_pins xlconcat_1/In7]
  connect_bd_net -net ethernet_subsystem_dout [get_bd_pins zynq_ultra_ps_e_0/pl_ps_irq0] [get_bd_pins ethernet_subsystem/dout]
  connect_bd_net -net ethernet_subsystem_gem2_phy_rst_n [get_bd_ports gem1_phy_rst_n] [get_bd_pins ethernet_subsystem/gem1_phy_rst_n]
  connect_bd_net -net ethernet_subsystem_gem3_phy_rst_n [get_bd_ports gem2_phy_rst_n] [get_bd_pins ethernet_subsystem/gem2_phy_rst_n]
  connect_bd_net -net gate_driver_A_gate_drive [get_bd_ports gate_drive_phase_a] [get_bd_pins gate_driver/gate_drive_phase_a] -boundary_type upper
  connect_bd_net -net gate_driver_A_gate_drive [get_bd_ports gate_drive_phase_a] [get_bd_pins ila_gate_driver/probe0] -boundary_type upper
  connect_bd_net -net gate_driver_B_gate_drive [get_bd_ports gate_drive_phase_b] [get_bd_pins gate_driver/gate_drive_phase_b] -boundary_type upper
  connect_bd_net -net gate_driver_B_gate_drive [get_bd_ports gate_drive_phase_b] [get_bd_pins ila_gate_driver/probe1] -boundary_type upper
  connect_bd_net -net gate_driver_C_gate_drive [get_bd_ports gate_drive_phase_c] [get_bd_pins gate_driver/gate_drive_phase_c] -boundary_type upper
  connect_bd_net -net gate_driver_C_gate_drive [get_bd_ports gate_drive_phase_c] [get_bd_pins ila_gate_driver/probe2] -boundary_type upper
  connect_bd_net -net gate_driver_Dout [get_bd_pins gate_driver/phase_lower] [get_bd_pins ila_gate_driver/probe3]
  connect_bd_net -net gate_driver_Dout1 [get_bd_pins gate_driver/phase_upper] [get_bd_pins ila_gate_driver/probe4]
  connect_bd_net -net gem1_clk_in_1 [get_bd_ports gem1_clk_in] [get_bd_pins ethernet_subsystem/gem1_clk_in]
  connect_bd_net -net gem2_clk_in_1 [get_bd_ports gem2_clk_in] [get_bd_pins ethernet_subsystem/gem2_clk_in]
  connect_bd_net -net hls_qei_top_0_qei_RPM_THETA_m_TDATA [get_bd_pins ila_enc_qei/probe0] [get_bd_pins hls_qei_top_0/qei_RPM_THETA_m_TDATA]
  connect_bd_net -net hls_qei_top_0_qei_RPM_THETA_m_TVALID [get_bd_pins ila_enc_qei/probe1] [get_bd_pins hls_qei_top_0/qei_RPM_THETA_m_TVALID]
  connect_bd_net -net hls_qei_top_0_qei_dir_TDATA [get_bd_pins ila_enc_qei/probe2] [get_bd_pins hls_qei_top_0/qei_dir_TDATA]
  connect_bd_net -net hls_qei_top_0_qei_dir_TVALID [get_bd_pins ila_enc_qei/probe3] [get_bd_pins hls_qei_top_0/qei_dir_TVALID]
  connect_bd_net -net hls_qei_top_0_qei_err_TDATA [get_bd_pins ila_enc_qei/probe7] [get_bd_pins hls_qei_top_0/qei_err_TDATA]
  connect_bd_net -net hls_qei_top_0_qei_err_TVALID [get_bd_pins ila_enc_qei/probe8] [get_bd_pins hls_qei_top_0/qei_err_TVALID]
  connect_bd_net -net motor_pa_data_a_1 [get_bd_ports motor_pa_data_v] [get_bd_pins xlconcat_1/In0]
  connect_bd_net -net motor_pa_data_b_1 [get_bd_ports motor_pa_data_i] [get_bd_pins xlconcat_1/In1]
  connect_bd_net -net motor_pb_data_a_1 [get_bd_ports motor_pb_data_v] [get_bd_pins xlconcat_1/In2]
  connect_bd_net -net motor_pb_data_b_1 [get_bd_ports motor_pb_data_i] [get_bd_pins xlconcat_1/In3]
  connect_bd_net -net motor_pc_data_a_1 [get_bd_ports motor_pc_data_v] [get_bd_pins xlconcat_1/In4]
  connect_bd_net -net motor_pc_data_b_1 [get_bd_ports motor_pc_data_i] [get_bd_pins xlconcat_1/In5]
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_lpd_aclk] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins zynq_ultra_ps_e_0/saxihp0_fpd_aclk] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins axi_gpio_pmod/s_axi_aclk] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins axi_interconnect_cntrl/ACLK] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins axi_interconnect_cntrl/M00_ACLK] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins axi_interconnect_cntrl/M01_ACLK] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins axi_interconnect_cntrl/M02_ACLK] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins axi_interconnect_cntrl/M03_ACLK] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins axi_interconnect_cntrl/S00_ACLK] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins axi_quad_spi_0/ext_spi_clk] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins axi_quad_spi_0/s_axi_aclk] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins ethernet_subsystem/m_axi_mm2s_aclk] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins gate_driver/sys_clk] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins ila_enc_qei/clk] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins ila_gate_driver/clk] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins hls_qei_top_0/ap_clk] -boundary_type upper
  connect_bd_net -net pl_clk0 [get_bd_pins ADC/CLK] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] -boundary_type upper
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins ADC/SCLK_RESETn] [get_bd_pins proc_sys_reset_1/peripheral_aresetn]
  connect_bd_net -net xlconcat_1_dout [get_bd_pins ADC/SDATA] [get_bd_pins xlconcat_1/dout]
  connect_bd_net -net xlconcat_int_dout [get_bd_pins zynq_ultra_ps_e_0/pl_ps_irq1] [get_bd_pins xlconcat_int/dout]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins hls_qei_top_0/ap_start] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins ADC/UPDATE] [get_bd_pins xlconstant_1/dout]
  connect_bd_net -net xlslice_0_Dout [get_bd_ports gate_drive_en] [get_bd_pins ila_gate_driver/probe5] -boundary_type upper
  connect_bd_net -net xlslice_0_Dout [get_bd_ports gate_drive_en] [get_bd_pins xlslice_gpio_0/Dout] -boundary_type upper
  connect_bd_net -net xlslice_0_Dout1 [get_bd_ports fan_en_b] [get_bd_pins xlslice_fan/Dout]
  connect_bd_net -net xlslice_0_Dout2 [get_bd_ports motor_adc_cs_n] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_ports dc_link_adc_cs_n] [get_bd_pins xlslice_1/Dout]
  connect_bd_net -net xlslice_gpio_1_Dout [get_bd_ports brake_cntrl] [get_bd_pins xlslice_gpio_1/Dout]
  connect_bd_net -net xlslice_gpio_2_Dout [get_bd_ports one_wire] [get_bd_pins xlslice_gpio_2/Dout]
  connect_bd_net -net zynq_ultra_ps_e_0_emio_gpio_o [get_bd_pins zynq_ultra_ps_e_0/emio_gpio_o] [get_bd_pins xlslice_gpio_0/Din] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_emio_gpio_o [get_bd_pins zynq_ultra_ps_e_0/emio_gpio_o] [get_bd_pins xlslice_gpio_1/Din] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_emio_gpio_o [get_bd_pins zynq_ultra_ps_e_0/emio_gpio_o] [get_bd_pins xlslice_gpio_2/Din] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_emio_ttc0_wave_o [get_bd_pins zynq_ultra_ps_e_0/emio_ttc0_wave_o] [get_bd_pins gate_driver/ttc] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_emio_ttc0_wave_o [get_bd_pins zynq_ultra_ps_e_0/emio_ttc0_wave_o] [get_bd_pins xlslice_fan/Din] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins ADC/RESETn] [get_bd_pins axi_gpio_pmod/s_axi_aresetn] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins ADC/RESETn] [get_bd_pins axi_interconnect_cntrl/M00_ARESETN] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins ADC/RESETn] [get_bd_pins axi_interconnect_cntrl/M01_ARESETN] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins ADC/RESETn] [get_bd_pins axi_interconnect_cntrl/M02_ARESETN] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins ADC/RESETn] [get_bd_pins axi_interconnect_cntrl/M03_ARESETN] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins ADC/RESETn] [get_bd_pins axi_interconnect_cntrl/S00_ARESETN] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins ADC/RESETn] [get_bd_pins axi_quad_spi_0/s_axi_aresetn] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins ADC/RESETn] [get_bd_pins gate_driver/sys_rstn] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins ADC/RESETn] [get_bd_pins hls_qei_top_0/ap_rst_n] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins ADC/RESETn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn1 [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins ethernet_subsystem/ext_reset_in] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn1 [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins proc_sys_reset_0/ext_reset_in] -boundary_type upper
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn1 [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins proc_sys_reset_1/ext_reset_in] -boundary_type upper

  # Create address segments
  assign_bd_address -offset 0xA0010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs ADC/adc_hub_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs ethernet_subsystem/axi_dma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x80010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs ethernet_subsystem/axi_dma_1/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x80040000 -range 0x00040000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs ethernet_subsystem/axi_ethernet_0/s_axi/Reg0] -force
  assign_bd_address -offset 0x80080000 -range 0x00040000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs ethernet_subsystem/axi_ethernet_1/s_axi/Reg0] -force
  assign_bd_address -offset 0xA0020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs axi_gpio_pmod/S_AXI/Reg] -force
  assign_bd_address -offset 0xA0030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs axi_quad_spi_0/AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs hls_qei_top_0/s_axi_qei_args/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ethernet_subsystem/axi_dma_0/Data_MM2S] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ethernet_subsystem/axi_dma_0/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ethernet_subsystem/axi_dma_0/Data_SG] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ethernet_subsystem/axi_dma_1/Data_MM2S] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ethernet_subsystem/axi_dma_1/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ethernet_subsystem/axi_dma_1/Data_SG] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces ethernet_subsystem/axi_dma_0/Data_MM2S] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces ethernet_subsystem/axi_dma_0/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces ethernet_subsystem/axi_dma_0/Data_SG] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces ethernet_subsystem/axi_dma_1/Data_MM2S] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces ethernet_subsystem/axi_dma_1/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces ethernet_subsystem/axi_dma_1/Data_SG] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM]


  # Restore current instance
  current_bd_instance $oldCurInst

  # Create PFM attributes
  set_property PFM_NAME {xilinx:kd240_bist:kd240_bist:1.0} [get_files [current_bd_design].bd]
  set_property PFM.CLOCK {pl_clk0 {id "7" is_default "true" proc_sys_reset "/proc_sys_reset_0" status "fixed" freq_hz "96968727"}} [get_bd_cells /zynq_ultra_ps_e_0]
  set_property PFM.AXI_PORT {M_AXI_HPM1_FPD {memport "M_AXI_GP" sptag "" memory "" is_range "false"} S_AXI_HPC0_FPD {memport "S_AXI_HP" sptag "HPC0" memory "PS_0 HPC0_DDR_LOW" is_range "false"} S_AXI_HPC1_FPD {memport "S_AXI_HP" sptag "HPC1" memory "PS_0 HPC1_DDR_LOW" is_range "false"} S_AXI_HP1_FPD {memport "S_AXI_HP" sptag "HP1" memory "PS_0 HP1_DDR_LOW" is_range "false"} S_AXI_HP2_FPD {memport "S_AXI_HP" sptag "HP2" memory "PS_0 HP2_DDR_LOW" is_range "false"} S_AXI_HP3_FPD {memport "S_AXI_HP" sptag "HP3" memory "PS_0 HP3_DDR_LOW" is_range "false"} S_AXI_LPD {memport "MIG" sptag "LPD" memory "PS_0 LPD_DDR_LOW" is_range "false"}} [get_bd_cells /zynq_ultra_ps_e_0]

  #set_property PFM.IRQ {In2 {is_range "true"}} [get_bd_cells /xlconcat_int]

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


