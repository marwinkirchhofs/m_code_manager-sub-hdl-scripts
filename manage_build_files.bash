#!/usr/bin/env bash

# query action
echo "Please select an action:"
echo "f - fetch hardware build files form vivado run and store to 'latest'"
echo "    (only necessnary if you ran manual builds in vivado, instead of"
echo "    make flow or in-vivado mcm_prj_* instructions)"
echo "    the current mcm project config top module needs to align with the"
echo "    vivado run in question."
echo "e - export latest hardware build to named hardware builds"
echo "r - rename a hardware version"
echo "l - list exported hardware builds"
read action

case $action in 
    'f')
        read -p "specify vivado run name to fetch (empty will fetch 'impl_1'): " hw_run
        if [[ -z $hw_run ]]; then
            hw_run="impl_1"
        fi
        module_top=$(python3 _T_DIR_SCRIPTS_T_/_T_SCRIPT_READ_JSON_VAR_T_ _T_FILE_PROJECT_CONFIG_T_ top)
        dir_hw_run="_vivado_prj/$(ls _vivado_prj | grep runs)/${hw_run}"
        mkdir -p _T_DIR_HW_EXPORT_T_/latest
        cp ${dir_hw_run}/${module_top}.{bit,ltx} _T_DIR_HW_EXPORT_T_/latest
        file_sysdef=${dir_hw_run}/${module_top}.sysdef
        if [[ -f ${file_sysdef} ]]; then
            cp ${file_sysdef} _T_DIR_HW_EXPORT_T_/latest
        fi
        ;;
    'e')
        read -p "specify the hardware build name: " hardware_version
        mkdir _T_DIR_HW_EXPORT_T_/$hardware_version
        cp _T_DIR_HW_EXPORT_T_/{latest/*,$hardware_version}
        ;;
    'r')
        read -p "specify the hardware build to be renamed: " hardware_version_old
        read -p "specify the new name: " hardware_version_new
        mv _T_DIR_HW_EXPORT_T_/{$hardware_version_old,$hardware_version_new}
        ;;
    'l')
        ls _T_DIR_HW_EXPORT_T_
        ;;
    *)
        echo "Unsupported action '$action'"
        ;;
esac

