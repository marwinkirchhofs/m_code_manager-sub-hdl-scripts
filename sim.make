#!/usr/bin/env bash

include ../_T_FILE_MAKE_VARIABLES_T_

############################################################
# VARIABLES
############################################################

##############################
# PATHS
##############################

DIR_TRACE		:= trace
FILE_TRACE		:= ${DIR_TRACE}/${SIM_TOP}_trace.fst
FILE_GTKW_SAVE	:= ${DIR_TRACE}/${SIM_TOP}_trace.gtkw

# VERILATOR
DIR_VL_OBJ		:= vl_out

##############################
# OPTIONS
##############################

# VERILATOR

VL_WARNING		:= -Wall -Wno-fatal
# explicitly specify the top module
VL_TOP			:= --top ${SIM_TOP}
# enable automatic tracing
VL_TRACE		:= --trace-fst --trace-depth 3 --trace-structs
# switch between SystemC and Cpp
VL_OUT_LANG		:= -sc
# enable SystemVerilog support
VL_IN_LANG		:= -sv
# build exe and enable the maximum number of parallel jobs
VL_ADD_OPTS		:= --build --exe -j
# additional cpp headers
ifdef SRC_SIM_CPP_INCL
VL_CPP_INCL		:= -CFLAGS "$(addprefix -I,${SRC_SIM_CPP_INCL})"
endif
# pass object output directory and trace file name (and yes, the thousands of 
# backslashes in the CFLAGS are needed: 1. to g++ as \", 2. to the sc_main as ", 
# thus as a string)
VL_DIR_OUT		:= --Mdir ${DIR_VL_OBJ} \
				   -CFLAGS "\
				   		-Ofast \
				   		-DVL_SIM \
				   		-DDIR_TRACE=\\\"${DIR_TRACE}\\\" \
				   		-DFILE_TRACE=\\\"${FILE_TRACE}\\\" \
						"

# agglomerate the options for linting and simulation
VL_OPTIONS		:= ${VL_WARNING} \
				   ${VL_TOP} \
				   ${VL_OUT_LANG} ${VL_IN_LANG} \
				   ${VL_TRACE} \
				   ${VL_ADD_OPTS} \
				   ${VL_CPP_INCL} \
				   ${VL_DIR_OUT}

VL_LINT_OPTIONS	:= ${VL_WARNING} \
				   ${VL_IN_LANG} \
				   --lint-only

# GTKWAVE
GTKW_OPTIONS	:= --saveonexit --output /dev/null


############################################################
# TARGETS
############################################################

##############################
# LINTING
##############################
# It is more convenient to place the effective lint-only targets in this 
# makefile because all the verilator options are set up here.
#
# For providing additional verilator options (like excluding certain warnings in
# the first place), one can specify these as a string in vl_opts:
# make lint vl_opts="-Wno-STMTDLY -Wno-PINCONNECTEMPTY"

.PHONY: vl_lint
vl_lint:
	verilator ${VL_LINT_OPTIONS} ${vl_opts} ${SRC_RTL_VLOG}

##############################
# SIMULATION
##############################

.PHONY: sim
sim: ${SIMULATOR}_sim

# VERILATOR

.PHONY: vl_start_gui
vl_start_gui:
	# execute gtkwave in separate shell so that it can run in the background and 
	# you can still use the terminal you invoked it from
	@bash -c "gtkwave ${GTKW_OPTIONS} ${FILE_TRACE} ${FILE_GTKW_SAVE} &"

# verilator_sim is needed as an alias to vl_sim to allow invoking verilator 
# simulation in both "expected" ways:
# - `make sim` with the simulator set to 'verilator' in project_config.json
# - `make vl_sim` because we are lazy with typing
.PHONY: vl_sim
vl_sim:	verilator_sim

.PHONY: verilator_sim
verilator_sim: vl_build
	@mkdir -p ${DIR_TRACE}
	./${DIR_VL_OBJ}/V${SIM_TOP}

.PHONY: vl_build
vl_build:
	verilator ${VL_OPTIONS} ${DIR_PRJ_TOP}tb/tb_vl_${SIM_TOP}.cpp \
							${SRC_SIM_SYSC} ${SRC_RTL_VLOG}
