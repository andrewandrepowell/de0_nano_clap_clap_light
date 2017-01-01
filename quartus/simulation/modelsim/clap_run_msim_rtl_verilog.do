transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/projects/de0_nano_clap_clap_light/hdl {C:/projects/de0_nano_clap_clap_light/hdl/ToggleLight.v}
vlog -vlog01compat -work work +incdir+C:/projects/de0_nano_clap_clap_light/hdl {C:/projects/de0_nano_clap_clap_light/hdl/DetermineClap.v}
vlog -vlog01compat -work work +incdir+C:/projects/de0_nano_clap_clap_light/hdl {C:/projects/de0_nano_clap_clap_light/hdl/ComputeEnergy.v}
vlog -vlog01compat -work work +incdir+C:/projects/de0_nano_clap_clap_light/hdl {C:/projects/de0_nano_clap_clap_light/hdl/spimaster.v}
vlog -vlog01compat -work work +incdir+C:/projects/de0_nano_clap_clap_light/hdl {C:/projects/de0_nano_clap_clap_light/hdl/GetSignal.v}
vlog -vlog01compat -work work +incdir+C:/projects/de0_nano_clap_clap_light/hdl {C:/projects/de0_nano_clap_clap_light/hdl/fifo.v}
vlog -vlog01compat -work work +incdir+C:/projects/de0_nano_clap_clap_light/hdl {C:/projects/de0_nano_clap_clap_light/hdl/driver.v}
vlog -vlog01compat -work work +incdir+C:/projects/de0_nano_clap_clap_light/hdl {C:/projects/de0_nano_clap_clap_light/hdl/top2.v}

vlog -vlog01compat -work work +incdir+C:/projects/de0_nano_clap_clap_light/quartus/../hdl {C:/projects/de0_nano_clap_clap_light/quartus/../hdl/testbench.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  testbench

add wave *
view structure
view signals
run -all
