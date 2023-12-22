#!/bin/bash

if [ -d BSP/rtos ]; then
DEFAULT_NVT_CROSS=gcc-6.5-newlib-2.4-2019.11-arm-ca9-eabihf
DEFAULT_NVTCONFIG_FILE_NAME=.nvt_default
DEFAULT_NVT_ACTIVE_PROJ="rtos"
DEFAULT_NVT_MODEL_CFG="RTOS_BOOT_LINUX_NOR_EVB"
else
DEFAULT_NVT_CROSS=arm-ca9-linux-gnueabihf-6.5
DEFAULT_NVTCONFIG_FILE_NAME=.nvt_default
DEFAULT_NVT_ACTIVE_PROJ="Linux"
DEFAULT_NVT_MODEL_CFG="IPCAM1_RAMDISK_EVB"
fi

function hmm() {
cat <<EOF
Invoke ". build/envsetup.sh" from your shell to add the following functions to your environment:
- lunch:   lunch <OS> <ModelConfig> <Toolchain>
- croot:   Changes directory to the top of the tree.
- m:       Makes from the top of the tree.
- mr:      Makes rootfs.
- cso:     Copy shared libraries to rootfs.

Environemnt options:
- SANITIZE_HOST: Set to 'true' to use ASAN for all host modules. Note that
                 ASAN_OPTIONS=detect_leaks=0 will be set by default until the
                 build is leak-check clean.

Look at the source to view more functions. The complete list is:
EOF
	T=$(gettop)
	local A
	A=""
	for i in `cat $T/build/envsetup.sh | sed -n "/^[ \t]*function /s/function \([a-z_]*\).*/\1/p" | sort | uniq`; do
		A="$A $i"
	done
	echo $A
}

function show_env_by_name()
{
	echo $1 = ${!1}
}

function get_stuff_for_environment()
{
	echo "======================================== NVT Setting ========================================"
	show_env_by_name NVT_PRJCFG_CFG
	show_env_by_name NVT_PRJCFG_MODEL_CFG
	show_env_by_name LINUX_BUILD_TOP
	show_env_by_name UBOOT_DIR
	show_env_by_name NUTTX_DIR
	show_env_by_name OPTEE_DIR
	show_env_by_name KERNELDIR
	show_env_by_name BUSYBOX_DIR
	show_env_by_name TOYBOX_DIR
	show_env_by_name ROOTFS_DIR
	show_env_by_name APP_DIR
	show_env_by_name LIBRARY_DIR
	show_env_by_name INCLUDE_DIR
	show_env_by_name NVT_DRIVER_DIR
	show_env_by_name NVT_HDAL_DIR
	show_env_by_name NVT_VOS_DIR
	show_env_by_name NVT_RTOS_MAIN_DIR
	show_env_by_name SAMPLE_DIR
	show_env_by_name TOOLS_DIR
	show_env_by_name OUTPUT_DIR
	show_env_by_name LOGS_DIR
	show_env_by_name BUILD_DIR
	show_env_by_name CONFIG_DIR
	show_env_by_name PLATFORM_CFLAGS
	show_env_by_name PLATFORM_AFLAGS
	show_env_by_name NVT_HOST
	show_env_by_name NVT_LINUX_VER
	show_env_by_name NVT_MULTI_CORES_FLAG
	show_env_by_name CROSS_COMPILE
	show_env_by_name CROSS_TOOLCHAIN_PATH
	show_env_by_name CROSS_TOOLCHAIN_BIN_PATH
	show_env_by_name SYSROOT_PATH
	show_env_by_name UBOOT_CROSS_COMPILE
	show_env_by_name AS
	show_env_by_name CC
	show_env_by_name CXX
	show_env_by_name LD
	show_env_by_name LDD
	show_env_by_name AR
	show_env_by_name NM
	show_env_by_name GDB
	show_env_by_name STRIP
	show_env_by_name OBJCOPY
	show_env_by_name OBJDUMP
	show_env_by_name PATH
	show_env_by_name LD_LIBRARY_PATH
	echo "============================================================================================="
}

function clear_nvt_environment()
{
	rm -rf ${BUILD_DIR}/${DEFAULT_NVTCONFIG_FILE_NAME}
	unset NVT_PRJCFG_CFG
	unset NVT_PRJCFG_MODEL_CFG
	unset LINUX_BUILD_TOP
	unset UBOOT_DIR
	unset NUTTX_DIR
	unset OPTEE_DIR
	unset KERNELDIR
	unset BUSYBOX_DIR
	unset TOYBOX_DIR
	unset ROOTFS_DIR
	unset APP_DIR
	unset LIBRARY_DIR
	unset NVT_DRIVER_DIR
	unset NVT_HDAL_DIR
	unset NVT_VOS_DIR
	unset NVT_RTOS_MAIN_DIR
	unset SAMPLE_DIR
	unset TOOLS_DIR
	unset OUTPUT_DIR
	unset LOGS_DIR
	unset BUILD_DIR
	unset CONFIG_DIR
	unset NVT_DSP_DIR
	unset PLATFORM_CFLAGS
	unset PLATFORM_AFLAGS
	unset NVT_HOST
	unset NVT_LINUX_VER
	unset NVT_CROSS
	unset CROSS_COMPILE
	unset CROSS_TOOLCHAIN_PATH
	unset CROSS_TOOLCHAIN_BIN_PATH
	unset SYSROOT_PATH
	unset UBOOT_CROSS_COMPILE
	unset KBUILD_OUTPUT
	unset NVT_MULTI_CORES_FLAG
	unset AS
	unset CC
	unset CXX
	unset LD
	unset LDD
	unset AR
	unset NM
	unset GDB
	unset STRIP
	unset OBJCOPY
	unset OBJDUMP
	unset NVT_GCOV
	unset NVT_KGCOV
}

function reset_nvt_environment_crosscompiler()
{
	unset AS
	unset CC
	unset CXX
	unset LD
	unset LDD
	unset AR
	unset NM
	unset GDB
	unset STRIP
	unset OBJCOPY
	unset OBJDUMP
	unset CPP
}
export -f reset_nvt_environment_crosscompiler

function restore_nvt_environment_crosscompiler()
{
	export AS="${CROSS_COMPILE}as"
	export CC="${CROSS_COMPILE}gcc"
	export CPP="${CROSS_COMPILE}gcc"
	export CXX="${CROSS_COMPILE}g++"
	export LD=${CROSS_COMPILE}ld
	export LDD="${CROSS_COMPILE}ldd"
	export AR=${CROSS_COMPILE}ar
	export NM=${CROSS_COMPILE}nm
	export GDB=${CROSS_COMPILE}gdb
	export STRIP=${CROSS_COMPILE}strip
	export OBJCOPY=${CROSS_COMPILE}objcopy
	export OBJDUMP=${CROSS_COMPILE}objdump
}
export -f restore_nvt_environment_crosscompiler

function chk_for_the_same_codebase()
{
	ret=`echo $NVT_PRJCFG_MODEL_CFG | grep ${PWD}`
	if [ -z $ret ]; then
		return 0
	else
		cfg_model=`echo $NVT_PRJCFG_MODEL_CFG | awk -F'ModelConfig.mk' '{print $1}'`
		if [ -d $cfg_model ]; then
			return 1;
		else
			return 0;
		fi
	fi
}

function gettop
{
	if [ -n "$LINUX_BUILD_TOP" ] ; then
		echo $LINUX_BUILD_TOP
		return
	fi
	echo $PWD
}

function gen_modelconfig()
{
	echo export NVT_PRJCFG_CFG=${NVT_PRJCFG_CFG} > ${BUILD_DIR}/${DEFAULT_NVTCONFIG_FILE_NAME}
	echo export NVT_CROSS=${NVT_CROSS} >> ${BUILD_DIR}/${DEFAULT_NVTCONFIG_FILE_NAME}
	echo -n export NVT_PRJCFG_MODEL_CFG='${CONFIG_DIR}/${NVT_PRJCFG_CFG}/' >> ${BUILD_DIR}/${DEFAULT_NVTCONFIG_FILE_NAME}
	MODEL=`echo $NVT_PRJCFG_MODEL_CFG | awk -F'/' '{print $(NF-1)}'`;
	echo ${MODEL}/ModelConfig.mk >> ${BUILD_DIR}/${DEFAULT_NVTCONFIG_FILE_NAME}
}

function setsymbolic()
{
	# remove old symbolic
	if [ -L code/hdal/drivers/k_driver/include/plat ]; then
		unlink code/hdal/drivers/k_driver/include/plat
	fi
	if [ -L base/hdal/drivers/k_driver/include/plat ]; then
		unlink base/hdal/drivers/k_driver/include/plat
	fi
	if [ -L code/hdal ]; then
		rm code/hdal
	fi
	if [ -L code/vos ]; then
		rm code/vos
	fi
	if [ -L code ]; then
		rm code
	fi
	if [ -L BSP/u-boot ]; then
		rm BSP/u-boot
	fi
	if [ -L BSP ]; then
		rm BSP
	fi
	if [ -d base ]; then
		# make new symbolic
		if [ $NVT_PRJCFG_CFG == "Linux" ]; then
			ln -s base/linux-BSP BSP
			ln -s ../u-boot BSP/u-boot
			ln -s base/linux-code code
			ln -s ../hdal code/hdal
			ln -s ../vos code/vos
		elif [ $NVT_PRJCFG_CFG == "rtos" ]; then
			ln -s base/rtos-BSP BSP
			ln -s ../u-boot BSP/u-boot
			ln -s base/rtos-code code
			ln -s ../hdal code/hdal
			ln -s ../vos code/vos
			if [ -L code/hdal/drivers/k_driver/include/plat ]; then
				unlink code/hdal/drivers/k_driver/include/plat
			fi
		fi
	fi
	if [ $NVT_PRJCFG_CFG == "rtos" ]; then
		if [ ${RTOS_CPU_TYPE} == "cortex-a9" ]; then
			ln -s rtos_na51055 code/hdal/drivers/k_driver/include/plat
		else
			ln -s rtos_na51000 code/hdal/drivers/k_driver/include/plat
		fi
	fi
}

function setpaths()
{
	T=$(gettop)
	if [ ! "$T" ]; then
		echo "Couldn't locate the top of the tree.  Try setting TOP."
		return
	fi

	##################################################################
	#                                                                #
	#              Read me before you modify this code               #
	#                                                                #
	#   This function sets CROSS_TOOLCHAIN_PATH to what it is adding #
	#   to PATH, and the next time it is run, it removes that from   #
	#   PATH.  This is required so lunch can be run more than once   #
	#   and still have working paths.                                #
	#                                                                #
	##################################################################

	# Note: on windows/cygwin, LINUX_BUILD_PATH will contain spaces
	# due to "C:\Program Files" being in the path.

	# out with the old
	if [ -n "$LINUX_BUILD_PATH" ] ; then
		export PATH=${PATH/$LINUX_BUILD_PATH/}
		# strip leading ':', if any
		export PATH=${PATH#*:}
	fi
	if [ -n "$CROSS_TOOLCHAIN_PATH" ] ; then
		export LD_LIBRARY_PATH=${LD_LIBRARY_PATH/$CROSS_TOOLCHAIN_PATH\/usr\/local\/lib}
		# strip leading ':', if any
		export LD_LIBRARY_PATH=${LD_LIBRARY_PATH#*:}
	fi
	if [ -n "$XM4TOOLS" ] ; then
		export PATH=${PATH/$XM4TOOL/}
		# strip leading ':', if any
		export PATH=${PATH#*:}
		export PATH=${PATH%:\.}
	fi

	chk_for_the_same_codebase
	ret=$?
	# To config default setting if first get codebase.
	if [ -z "$NVT_PRJCFG_MODEL_CFG" ] || [ $ret -ne 1 ]; then
		export NVT_PRJCFG_CFG=${DEFAULT_NVT_ACTIVE_PROJ}
		export NVT_PRJCFG_MODEL_CFG=${CONFIG_DIR}/${NVT_PRJCFG_CFG}/cfg_${DEFAULT_NVT_MODEL_CFG}/ModelConfig.mk
	fi

	make -C ${CONFIG_DIR} clean > /dev/null 2>&1
	make -C ${CONFIG_DIR} gen_dtb
	make -C ${CONFIG_DIR} gen_modelcfg

	# envconfig.sh will handle this function to do the toolchain environment setup.
	setpath_toolchain_config
	export AS="${CROSS_COMPILE}as"
	export CC="${CROSS_COMPILE}gcc"
	export CXX="${CROSS_COMPILE}g++"
	export LD=${CROSS_COMPILE}ld
	export LDD="${CROSS_COMPILE}ldd"
	export AR=${CROSS_COMPILE}ar
	export NM=${CROSS_COMPILE}nm
	export GDB=${CROSS_COMPILE}gdb
	export STRIP=${CROSS_COMPILE}strip
	export OBJCOPY=${CROSS_COMPILE}objcopy
	export OBJDUMP=${CROSS_COMPILE}objdump
	if [ -z "`echo $LD_LIBRARY_PATH | grep ${CROSS_TOOLCHAIN_PATH}/usr/local/lib`" ]; then
		if [ ! -z "${LD_LIBRARY_PATH}" ]; then
			export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${CROSS_TOOLCHAIN_PATH}/usr/local/lib
		else
			export LD_LIBRARY_PATH=${CROSS_TOOLCHAIN_PATH}/usr/local/lib
		fi
		if [ $NVT_PRJCFG_CFG == "rtos" ]; then
			if [ -z "`echo $LD_LIBRARY_PATH | grep ${UBOOT_CROSS_TOOLCHAIN_PATH}/usr/local/lib`" ]; then
				export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${UBOOT_CROSS_TOOLCHAIN_PATH}/usr/local/lib
			fi
		fi
	fi

	gen_modelconfig

	if [ -d /opt/CEVA-ToolBox/V17/XM4/ ]; then
			source /opt/CEVA-ToolBox/V17/XM4/CEVA-XM4_set.sh
	fi
}

# Clear this variable.  It will be built up again when the vendorsetup.sh
# files are included at the end of this file.
unset LUNCH_MENU_CHOICES
function add_lunch_combo()
{
	local new_combo=$1
	local c
	for c in ${LUNCH_MENU_CHOICES[@]} ; do
		if [ "$new_combo" = "$c" ] ; then
			return
		fi
	done
	LUNCH_MENU_CHOICES=(${LUNCH_MENU_CHOICES[@]} $new_combo)
}

unset LUNCH_TOOLCHAIN_MENU_CHOICES
function add_lunch_toolchain_combo()
{
	local new_combo=$1
	local c
	for c in ${LUNCH_TOOLCHAIN_MENU_CHOICES[@]} ; do
		if [ "$new_combo" = "$c" ] ; then
			return
		fi
	done
	LUNCH_TOOLCHAIN_MENU_CHOICES=(${LUNCH_TOOLCHAIN_MENU_CHOICES[@]} $new_combo)
}

unset LUNCH_PROJ_CONFIG_MENU_CHOICES
function add_lunch_proj_config_combo()
{
	local new_combo=$1
	local c
	for c in ${LUNCH_PROJ_CONFIG_MENU_CHOICES[@]} ; do
		if [ "$new_combo" = "$c" ] ; then
			return
		fi
	done
	LUNCH_PROJ_CONFIG_MENU_CHOICES=(${LUNCH_PROJ_CONFIG_MENU_CHOICES[@]} $new_combo)
}

function add_modelconfig()
{
	unset LUNCH_MENU_CHOICES
	local model_list=`cd ${CONFIG_DIR}/${NVT_PRJCFG_CFG}; ls -d */ | grep -v cfg_gen | grep -v include | cut -f1 -d'/'`
	for n in ${model_list}
	do
		add_lunch_combo $n
	done
}

function print_lunch_prjcfg_menu()
{
	local uname=$(uname)
	echo
	echo "You're building on" $uname
	echo
	echo "Lunch menu... select your Project config:"

	local i=1
	local choice
	for choice in ${LUNCH_PROJ_CONFIG_MENU_CHOICES[@]}
	do
		echo "     $i. $choice"
		i=$(($i+1))
	done

	echo
}

function print_lunch_menu()
{
	local uname=$(uname)
	echo
	echo "You're building on" $uname
	echo
	echo "Lunch menu... select your Model config:"

	local i=1
	local choice
	for choice in ${LUNCH_MENU_CHOICES[@]}
	do
		echo "     $i. $choice"
		i=$(($i+1))
	done

	echo
}

function print_lunch_toolchain_menu()
{
	local uname=$(uname)
	echo
	echo
	echo "Lunch menu... select your toolchain:"

	local i=1
	local choice
	for choice in ${LUNCH_TOOLCHAIN_MENU_CHOICES[@]}
	do
		echo "     $i. $choice"
		i=$(($i+1))
	done

	echo
}

function check_is_clean()
{
	if [ -d $ROOTFS_DIR/bin ]; then
		return 0;
	elif [ -d $OUTPUT_DIR ]; then
		return 0;
	else
		return 1;
	fi
}

function check_path_is_right()
{
	if [ ! -z "$LINUX_BUILD_TOP" ]; then
		cur_path=`pwd`;
		cond=`echo $cur_path | grep $LINUX_BUILD_TOP`
		if [ ! -z $cond ]; then
			return 1;
		else
			return 0;
		fi
	else
		return 0;
	fi
}

# Check if the toolchain menu is updated
function check_toolchain_default_setting_is_right()
{
	local cur_conf=$1
	local i=1
	local choice
	for choice in ${LUNCH_TOOLCHAIN_MENU_CHOICES[@]}
	do
		if [ "$choice" == "$cur_conf" ]; then
			return 1;
		fi
		i=$(($i+1))
	done
	return 0;
}

function lunch()
{
	# Add OS type menu
	add_prjcfgconfig
	local answer

	check_path_is_right
	if [ $? -eq 0 ]; then
		echo -e "\e[1;45mYour path is wrong!!\e[0m: SDK top path is $LINUX_BUILD_TOP\r\n"
		return 0;
	fi

	# Show error if your codebase is not clean
	check_is_clean
	if [ $? -eq 0 ]; then
		echo -e "\e[1;45mChange model\e[0m: The menu can't be launched, please do clean build\e[1;45m(\$make clean)\e[0m first\r\n"
		echo -e "\e[1;37mCurrent selection: \e[0m"
		echo -e "\e[1;33m\t\tProject Config: $NVT_PRJCFG_CFG\e[0m"
		echo -e "\e[1;33m\t\tModel Config: `echo ${NVT_PRJCFG_MODEL_CFG} | awk -F'/' '{print $(NF-1)}'`\e[0m"
		echo -e "\e[1;33m\t\ttoolchain: ${NVT_CROSS}\e[0m"
		return 0;
	fi

	# To load previous setting or default setting
	# Include previous default setting
	if [ -f ${BUILD_DIR}/${DEFAULT_NVTCONFIG_FILE_NAME} ]; then
		echo "Loading default..."
		source ${BUILD_DIR}/${DEFAULT_NVTCONFIG_FILE_NAME}
		NVT_DEFAULT_NVT_MODEL=`echo ${NVT_PRJCFG_MODEL_CFG} | awk -F'/' '{print $(NF-1)}'`
		NVT_DEFAULT_NVT_CROSS=${NVT_CROSS}
		NVT_DEFAULT_PRJCFG_CFG=${NVT_PRJCFG_CFG}
	else
		NVT_DEFAULT_PRJCFG_CFG=${DEFAULT_NVT_ACTIVE_PROJ}
		NVT_DEFAULT_NVT_MODEL=${DEFAULT_NVT_MODEL_CFG}
		NVT_DEFAULT_NVT_CROSS=${DEFAULT_NVT_CROSS}
	fi

	check_toolchain_default_setting_is_right ${NVT_DEFAULT_NVT_CROSS}
	if [ $? -eq 0 ]; then
		NVT_DEFAULT_NVT_CROSS=${DEFAULT_NVT_CROSS}
	fi

	# To select "OS" type: Pure Linux, rtos...etc
	if [ "$1" ] ; then
		num=1
		answer="NONE"
		for n in ${LUNCH_PROJ_CONFIG_MENU_CHOICES[@]}
		do
			if [ "$1" == "$n" ]; then
				answer=$num
				break
			fi
			num=$((num + 1))
		done
	else
		print_lunch_prjcfg_menu
		echo -n "Which would you like? [${NVT_DEFAULT_PRJCFG_CFG}] "
		read answer
	fi

	local selection=
	if [ -z "$answer" ]
	then
		selection=${NVT_DEFAULT_PRJCFG_CFG}
	elif (echo -n $answer | grep -q -e "^[0-9][0-9]*$")
	then
		if [ $answer -le ${#LUNCH_PROJ_CONFIG_MENU_CHOICES[@]} ]
		then
			selection=${LUNCH_PROJ_CONFIG_MENU_CHOICES[$(($answer-1))]}
			export NVT_PRJCFG_CFG=${selection}
		fi
	elif (echo -n $answer | grep -q -e "^[^\-][^\-]*-[^\-][^\-]*$")
	then
		selection=$answer
	fi

	if [ -z "$selection" ]
	then
		echo
		echo "Invalid lunch project config combo: $answer"
		return 1
	fi

	# Model config selection: the models will have different OS combination
	# Linux: Model_1, Model_2
	# RTOS: Model_3, Model_4
	add_modelconfig
	if [ "$2" ] ; then
		num=1
		answer="NONE"
		for n in ${LUNCH_MENU_CHOICES[@]}
		do
			if [ "$2" == "$n" ]; then
				answer=$num
				break
			fi
			num=$((num + 1))
		done
	else
		print_lunch_menu
		echo -n "Which would you like? [${NVT_DEFAULT_NVT_MODEL}] "
		read answer
	fi

	local selection=

	if [ -z "$answer" ]
	then
		selection=${NVT_DEFAULT_NVT_MODEL}
	elif (echo -n $answer | grep -q -e "^[0-9][0-9]*$")
	then
		if [ $answer -le ${#LUNCH_MENU_CHOICES[@]} ]
		then
			selection=${LUNCH_MENU_CHOICES[$(($answer-1))]}
		fi
	elif (echo -n $answer | grep -q -e "^[^\-][^\-]*-[^\-][^\-]*$")
	then
		selection=$answer
	fi

	if [ -z "$selection" ]
	then
		echo
		echo "Invalid lunch model config combo: $answer"
		return 1
	fi

	export NVT_PRJCFG_MODEL_CFG=${CONFIG_DIR}/${NVT_PRJCFG_CFG}/${selection}/ModelConfig.mk

	add_lunch_toolchain_menu
	if [ "$3" ] ; then
		num=1
		answer="NONE"

		for n in ${LUNCH_TOOLCHAIN_MENU_CHOICES[@]}
		do
			if [ "$3" == "$n" ]; then
				answer=$num
				break
			fi
			num=$((num + 1))
		done
	else
		print_lunch_toolchain_menu
		echo -n "Which toolchain would you like? [${NVT_DEFAULT_NVT_CROSS}] "
		read answer
	fi

	local selection=

	if [ -z "$answer" ]
	then
		selection=${NVT_DEFAULT_NVT_CROSS}
	elif (echo -n $answer | grep -q -e "^[0-9][0-9]*$")
	then
		if [ $answer -le ${#LUNCH_TOOLCHAIN_MENU_CHOICES[@]} ]
		then
			selection=${LUNCH_TOOLCHAIN_MENU_CHOICES[$(($answer-1))]}
		fi
	elif (echo -n $answer | grep -q -e "^[^\-][^\-]*-[^\-][^\-]*$")
	then
		selection=$answer
	fi

	if [ -z "$selection" ]
	then
		echo
		echo "Invalid lunch toolchain combo: $answer"
		return 1
	fi

	export NVT_CROSS=${selection}
	echo -e "\e[1;33mToolchain: ${NVT_CROSS}\e[0m"
	echo -e "\e[1;33mProject: ${NVT_PRJCFG_CFG}\e[0m"
	echo -e "\e[1;33mModel: ${NVT_PRJCFG_MODEL_CFG}\e[0m"
	set_stuff_for_environment
}

# Tab completion for lunch.
function _lunch()
{
	local cur prev opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	COMPREPLY=( $(compgen -W "${LUNCH_MENU_CHOICES[*]}" -- ${cur}) )
	return 0
}
complete -F _lunch lunch

function addcompletions()
{
	local T dir f

	# Keep us from trying to run in something that isn't bash.
	if [ -z "${BASH_VERSION}" ]; then
		return
	fi

	# Keep us from trying to run in bash that's too old.
	if [ ${BASH_VERSINFO[0]} -lt 3 ]; then
		return
	fi

	dir="sdk/bash_completion"
	if [ -d ${dir} ]; then
		for f in `/bin/ls ${dir}/[a-z]*.bash 2> /dev/null`; do
			echo "including $f"
			. $f
		done
	fi
}

function croot()
{
	T=$(gettop)
	if [ "$T" ]; then
		\cd $(gettop)
	else
		echo "Couldn't locate the top of the tree.  Try setting TOP."
	fi
}

function m()
{
	local T=$(gettop)
	if [ "$T" ]; then
		cd $(gettop);make;cd -
	else
		echo "Couldn't locate the top of the tree.  Try setting TOP."
	fi
}

function mr()
{
	local T=$(gettop)
	if [ "$T" ]; then
		cd $(gettop);make rootfs;cd -
	else
		echo "Couldn't locate the top of the tree.  Try setting TOP."
	fi
}

function cso()
{
	file=$(gettop)/build/copyso.sh
	sh $file
}

if [ "x$SHELL" != "x/bin/bash" ]; then
	case `ps -o command -p $$` in
		*bash*)
			;;
		*)
			echo "WARNING: Only bash is supported, use of other shell would lead to erroneous results"
			;;
	esac
fi

if [ -f ${PWD}/build/envsetup.sh ]; then
	# include global options
	source build/envoption.sh
	source build/envconfig.sh
	# Include previous default setting
	if [ -f ${PWD}/build/${DEFAULT_NVTCONFIG_FILE_NAME} ]; then
		# export necessary dirs for load .nvt_default
		export LINUX_BUILD_TOP=$PWD
		export BUILD_DIR=${LINUX_BUILD_TOP}/build
		export CONFIG_DIR=${LINUX_BUILD_TOP}/configs
		source ${BUILD_DIR}/${DEFAULT_NVTCONFIG_FILE_NAME}
	fi
	set_stuff_for_environment
	echo "Env setup configured"
else
	echo "Can't support execute env setup on ${PWD}"
fi
