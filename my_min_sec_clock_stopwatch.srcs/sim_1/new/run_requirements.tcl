# In the Vivado Tcl console, with this project open:
# source ./my_min_sec_clock_stopwatch.srcs/sim_1/new/run_requirements.tcl
set_property top tb_top_clock_stopwatch [get_filesets sim_1]
set_property top_auto_set false [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation -simset sim_1 -mode behavioral
run all
