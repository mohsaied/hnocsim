if {[file exists msim_setup.tcl]} {
	source msim_setup.tcl
	dev_com
	com
    exit
} else {
	error "The msim_setup.tcl script does not exist. Please generate the example design RTL and simulation scripts. See ../../README.txt for help."
}
