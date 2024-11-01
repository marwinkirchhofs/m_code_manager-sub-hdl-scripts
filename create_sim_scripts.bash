#!/usr/bin/env bash

# note: most of this file's arguments rely on absolute paths, such that almost 
# nothing is determined here. This file is meant to be invoked by a make file, 
# which already has the absolute paths available.  Therefore this choice helps 
# with centralizing control over the file structure, because then only the 
# makefile root needs to actually know anything about the paths.
# for a similar same reason, for example sim_top is just passed here as an 
# argument, instead of fetched from project_config.json. The makefile has that 
# available anyway, so why do json stuff here if you can just pass it?

# arguments
# $1 - simulator
# $2 - simulation run script (absolute path); will be overwritten
# $3 - simulation prepare script (absolute path); will be overwritten
# $4 - simulation top module
# $5 - xilinx IP simulation export directory (absolute path)
# $6 - simulator args (one string with all args)

simulator=$1
target_sim_run=$2
target_sim_prepare=$3
target_sim_opt=$4
sim_top=$5
dir_xips_sim_out=$6
dir_xips_precompile=$7
xil_glbl_lib=$8
sim_args=$9

list_xips=$(ls $dir_xips_sim_out | grep xip_)

case $simulator in
    modelsim|questa )
        # TODO: update the entire comment. Also explain that questa has explicit 
        # optimization, modelsim has not (at this point), but the structure and 
        # library analysis is too similar to make it two different cases. More 
        # likely that an update would break one of the two because you forget 
        # something.
        # PREPARE SIM
        # map all the xilinx IP libraries to uniquely named libraries - example:
        # IP "xip_axi_blk_mem_gen" creates library xil_defaultlib
        # -> vmap xip_axi_blk_mem_gen_xil_defaultlib <path to xip_axi_blk_mem_gen xil_defaultlib>
        
        # (RUN SIM needs to come in between, because the information about the 
        # libs in both files is the same)
        case $simulator in
            modelsim)
                echo "vsim -voptargs=\"+acc\" $sim_args \\" > $target_sim_run
                ;;
            questa)
                echo "vsim $sim_args \\" > $target_sim_run
                echo "vopt -64 +acc \\" > $target_sim_opt
                ;;
        esac

        [[ -f $target_sim_prepare ]] && rm $target_sim_prepare
        # copy modelsim.ini from precompiled simulation libraries (only if 
        # a directory is passed and it exists)
        [[ ! -z ${dir_xips_precompile} ]] && [[ -d ${dir_xips_precompile} ]] && \
                echo "cp ${dir_xips_precompile}/modelsim.ini ." > $target_sim_prepare

        # STANDARD LIBS
        # xip-independent libs

        if [[ ! -z ${dir_xips_precompile} ]]; then
            # if there are precompiled xilinx IPs, make sure to always include 
            # unisim - it provides the simulation models for primitives. Might 
            # not always be necessary, but it hopefully doesn't hurt, and to 
            # determine if you actually need them you would have to check the 
            # source code, that's not viable.
            case $simulator in
                modelsim)
                    echo "-L unisim \\" >> $target_sim_run
                    ;;
                questa)
                    echo "-L unisim \\" >> $target_sim_opt
                    ;;
            esac
        fi

        # remember that the makeflow compiles the glbl module into its own 
        # library (if any xips are present)
        if [[ ! -z "$list_xips" ]]; then
            case $simulator in
                modelsim)
                    echo "-L $xil_glbl_lib \\" >> $target_sim_run
                    ;;
                questa)
                    echo "-L $xil_glbl_lib \\" >> $target_sim_opt
                    ;;
            esac
        fi

        for xip in $list_xips; do
            dir_xip=$dir_xips_sim_out/$xip/$simulator
            # only include libs that were successfully built/can successfully be executed
            if [[ ! -f $dir_xips_sim_out/$xip/$simulator/simulation_failed ]]; then
                # creates the list with full path names (the sed removes the 
                # trailing '/' caused by the -d opt)
                list_dir_msim_libs=$(ls -d $dir_xips_sim_out/$xip/$simulator/${simulator}_lib/msim/*/ \
                        | sed -e 's/\/$//')

                for dir_lib in $list_dir_msim_libs; do
                    lib=$(basename $dir_lib)

                    # prevent "unisim" from being added another time, it is 
                    # already included by this script by default
                    # TODO: check if you also need to do anything later on at 
                    # the external libs thing
                    [[ ${lib} == "unisim" ]] && continue;

                    # TODO: Went back from ${xip}_${lib} because it's impossible 
                    # in the general case to alter the lib name, because it's 
                    # hard-coded if the IP simulation model is in vhdl. Also it 
                    # has led to issues where questa would ask to "recompile" 
                    # a lib that was just compiled. But now this might break if 
                    # there are two different configurations present of the same 
                    # IP, so presumably it's a temporary solution
#                     top_level_lib_name="${xip}_${lib}"
                    if [[ ! ${lib} == "xil_defaultlib" ]]; then
                        top_level_lib_name="${lib}"
                    else
                        top_level_lib_name="${xip}_${lib}"
                    fi

                    echo "vmap ${top_level_lib_name} $dir_lib" >> $target_sim_prepare
                    case $simulator in
                        modelsim)
                            echo "-L ${top_level_lib_name} \\" >> $target_sim_run
                            ;;
                        questa)
                            echo "-L ${top_level_lib_name} \\" >> $target_sim_opt
                            ;;
                    esac
                done

                # add libraries from elaborate.do script (potentially only 
                # applies to questa)
                # -> from the elaborate.do script (if it exists), fetch all
                # `-L <lib>` and add them to the sim run script. (the xilinx 
                # directly vopt them with the IP-respective top so that you 
                # don't get to the libraries anymore)

                # we need to check libraries againts the single names (without 
                # preceding path) of the already compiled libraries in the IP 
                # directory -> if xil_defaultlib exists in the IP directory, you 
                # already vmap that at top-level. elaborate.do still specifies 
                # '-L xil_defaultlib' of course, but we must drop that.
                # (the ls will catch '_info' as well, but that's not an issue as 
                # long as no library is named exactly like that)

                if [[ -f $dir_xip/elaborate.do ]]; then
                    list_raw_msim_libs=$(ls $dir_xip/${simulator}_lib/msim)
                    list_xip_ext_libs=$(grep -r -o -E "\-L [[:alnum:]_]+" $dir_xip/elaborate.do | awk '{print $2}')
                    for ext_lib in $list_xip_ext_libs; do
                        ext_lib_compiled=false
                        for ip_comp_lib in $list_raw_msim_libs; do
                            if [[ "$ip_comp_lib" == "$ext_lib" ]]; then
                                ext_lib_compiled=true
                            fi
                        done
                        if [[ "$ext_lib_compiled" == "false" ]]; then
                            case $simulator in
                                modelsim)
                                    echo "-L $ext_lib \\" >> $target_sim_run
                                    ;;
                                questa)
                                    echo "-L $ext_lib \\" >> $target_sim_opt
                                    ;;
                            esac
                        fi
                    done
                fi
            fi
        done

        # FINISH RUN SIM
        case $simulator in
            modelsim)
                echo "-lib work \\" >> $target_sim_run
                # (you can just take the xil_defaultlib from the last IP, 
                # because it doesn't matter from which IP you take it. It's the 
                # same everywhere, it only provides glbl)
                [[ ! -z "$list_xips" ]] && \
                        echo "${xil_glbl_lib}.glbl \\" >> $target_sim_run
                echo "$sim_top" >> $target_sim_run
                ;;
            questa)
                echo "-lib work \\" >> $target_sim_run
                echo "-work work \\" >> $target_sim_opt
                [[ ! -z "$list_xips" ]] && \
                        echo "${xil_glbl_lib}.glbl \\" >> $target_sim_opt
                echo "$sim_top \\" >> $target_sim_opt
                echo "-o ${sim_top}_opt" >> $target_sim_opt
                echo "${sim_top}_opt" >> $target_sim_run
                ;;
        esac

        ;;
    *)
        echo "Simulator $simulator is unknown! No simulation run script can be generated"
        return 1
        ;;  
esac

return 0

# vim: ft=sh
