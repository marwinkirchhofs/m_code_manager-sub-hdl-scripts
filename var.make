
# global variables for the hierarchical make build/sim system
# 
# All variables that are not globally needed are defined in the respective 
# sub-makefiles

DIR_TCL         := ${DIR_PRJ_TOP}_T_DIR_SCRIPTS_T_
DIR_SIM         := ${DIR_PRJ_TOP}_T_DIR_SIM_T_
DIR_RTL         := ${DIR_PRJ_TOP}_T_DIR_RTL_T_
DIR_XIPS        := ${DIR_PRJ_TOP}_T_DIR_XILINX_IPS_T_

##############################
# PROJECT
##############################

# DIRECTORY
# This makefile gets included by subdirectory makefiles. Thus, without providing
# it with an absolute path any wildcard expansion would be executed relative
# from the respective working directory. For globally providing a list of source
# files, that doesn't work. These lines provide the directory of this
# variable passing makefile, effectively the project's top-level directory.
PATH_VAR_MAKEFILE	:= $(abspath $(lastword ${MAKEFILE_LIST}))
DIR_PRJ_TOP		:= $(dir ${PATH_VAR_MAKEFILE})

# select the simulation flow to be used:
# "verilator", "modelsim", "questasim"
SIMULATOR		:= $(shell python3 										\
				   ${DIR_PRJ_TOP}_T_DIR_SCRIPTS_T_/_T_SCRIPT_READ_JSON_VAR_T_ 	\
				   ${DIR_PRJ_TOP}_T_FILE_PROJECT_CONFIG_T_ simulator)
SIM_TOP         := $(shell python3 										\
				   ${DIR_PRJ_TOP}_T_DIR_SCRIPTS_T_/_T_SCRIPT_READ_JSON_VAR_T_ 	\
				   ${DIR_PRJ_TOP}_T_FILE_PROJECT_CONFIG_T_ sim_top)

##############################
# RTL SOURCES
##############################

SRC_RTL_SV		:= $(wildcard ${DIR_PRJ_TOP}rtl/*.sv)
SRC_RTL_V		:= $(wildcard ${DIR_PRJ_TOP}rtl/*.v)
SRC_RTL_VLOG	:= ${SRC_RTL_SV} ${SRC_RTL_V}
SRC_RTL_VHDL	:= $(wildcard ${DIR_PRJ_TOP}rtl/*.vhd)

SRC_RTL         := ${SRC_RTL_VLOG} ${SRC_RTL_VHDL}

# how to get the names of all defined modules?
# - we need to remove everything but the module name from the list of sources
#   -> basename (notdir ...)
# - we need to filter out any package or interface
#   -> filter-out (...)
# (filter-out only interprets the first '%' as a wildcard, that's why we need to
# strip the file names first such that _pkg/_if is at the end of the remaining
# string)
SRC_MODULES     := $(filter-out %_pkg %_if, $(basename $(notdir ${SRC_RTL})))
XIL_DEBUG_CORE_FILES := $(addsuffix .tcl,                                   \
                            $(addprefix ${DIR_XIPS}/xips_debug_cores_,${SRC_MODULES}))

# SRC_RTL_HLS		:= $(wildcard ${DIR_PRJ_TOP}hls/*/verilog/*.v)

##############################
# SIMULATION SOURCES
##############################

SRC_SIM_CPP_INCL	:= ${DIR_PRJ_TOP}tb
# SRC_SIM_CPP_INCL	:= ${DIR_PRJ_TOP}tb \
# 					   ${DIR_PRJ_TOP}tb/sysc_axi \
# 					   ${DIR_PRJ_TOP}hls/axi_counter/drivers
# SRC_SIM_SYSC	:= 	$(wildcard ${DIR_PRJ_TOP}tb/sysc_axi/*.cpp) \
# 					$(wildcard ${DIR_PRJ_TOP}sw/*.cpp)

##############################
# TOOL SETTINGS
##############################

# TODO: once that is needed (should it ever be needed), integrate 
# hls_export_lang into project_config.json and fetch it from there
# # HLS
# # set up the hls export language (either verilog or vhdl)
# HLS_EXPORT_LANG	:= verilog
# 
# ifeq (${HLS_EXPORT_LANG},verilog)
# HLS_EXPORT_LANG_SUFFIX	:= v
# else
# ifeq (${HLS_EXPORT_LANG},vhdl)
# HLS_EXPORT_LANG_SUFFIX	:= vhd
# endif
# endif

# vim: filetype=make
