# Custom PDN configuration for SRAM macro integration on sg13cmos5l.
#
# Partially derived from
# https://github.com/urish/ttihp-sram-test/blob/main/src/pdn_cfg.tcl.
#
# This file SHOULD work with all IHP SRAM macros (after rotation and patching
# with extend_pdn.py, although the rotation should be fixable), but was only
# tested with RM_IHPSG13_1P_1024x8_c2_bm_bist as of March 2026.
#
# TODO: bring up to date with changes made to LibreLane 3's default
# configuration (if any).

source $::env(SCRIPTS_DIR)/openroad/common/set_global_connections.tcl
set_global_connections

set secondary []
foreach vdd $::env(VDD_NETS) gnd $::env(GND_NETS) {
    if { $vdd != $::env(VDD_NET)} {
        lappend secondary $vdd
        set db_net [[ord::get_db_block] findNet $vdd]
        if {$db_net == "NULL"} {
            set net [odb::dbNet_create [ord::get_db_block] $vdd]
            $net setSpecial
            $net setSigType "POWER"
        }
    }
    if { $gnd != $::env(GND_NET)} {
        lappend secondary $gnd
        set db_net [[ord::get_db_block] findNet $gnd]
        if {$db_net == "NULL"} {
            set net [odb::dbNet_create [ord::get_db_block] $gnd]
            $net setSpecial
            $net setSigType "GROUND"
        }
    }
}

set_voltage_domain -name CORE -power $::env(VDD_NET) -ground $::env(GND_NET) \
    -secondary_power $secondary

# STDCELL grid exports Metal4 (Vertical) ONLY
define_pdn_grid \
    -name stdcell_grid \
    -starts_with POWER \
    -voltage_domain CORE \
    -pins "$::env(PDN_VERTICAL_LAYER)"

# Vertical stripes (Metal4)
add_pdn_stripe \
    -grid stdcell_grid \
    -layer $::env(PDN_VERTICAL_LAYER) \
    -width $::env(PDN_VWIDTH) \
    -pitch $::env(PDN_VPITCH) \
    -offset $::env(PDN_VOFFSET) \
    -spacing $::env(PDN_VSPACING) \
    -starts_with POWER -extend_to_core_ring

# Standard cell rails on Metal1
if { $::env(PDN_ENABLE_RAILS) == 1 } {
    add_pdn_stripe \
        -grid stdcell_grid \
        -layer $::env(PDN_RAIL_LAYER) \
        -width $::env(PDN_RAIL_WIDTH) \
        -followpins

    add_pdn_connect \
        -grid stdcell_grid \
        -layers "$::env(PDN_RAIL_LAYER) $::env(PDN_VERTICAL_LAYER)"
}

# SRAM macro grid & connections
define_pdn_grid \
    -macro \
    -default \
    -name macro \
    -starts_with POWER \
    -halo "$::env(PDN_HORIZONTAL_HALO) $::env(PDN_VERTICAL_HALO)"

# openroad doesn't like connecting power straps to rings on the same layer, even if the layer on the side the strap is touching is different, so avoid using Metal4.
add_pdn_ring \
    -grid macro \
    -layers "Metal2 Metal3" \
    -spacings "$::env(PDN_HSPACING) $::env(PDN_VSPACING)" \
    -widths "$::env(PDN_HWIDTH) $::env(PDN_VWIDTH)" \
    -core_offsets 11 \
    -add_connect

add_pdn_connect \
    -grid macro \
    -layers "Metal3 Metal4"

add_pdn_connect \
    -grid macro \
    -layers "Metal2 Metal4"
