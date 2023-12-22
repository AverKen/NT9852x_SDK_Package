#####################################################################################################################
#
#	Add for OS type: Linux or RTOS etc....
#
#####################################################################################################################
function add_prjcfgconfig()
{
	unset LUNCH_PROJ_CONFIG_MENU_CHOICES
	add_lunch_proj_config_combo Linux
	add_lunch_proj_config_combo rtos
}

#####################################################################################################################
#
#	Add for toolchain type: glibc, uclibc, newlib....etc
#
#####################################################################################################################
function add_lunch_toolchain_menu()
{
	unset LUNCH_TOOLCHAIN_MENU_CHOICES
	if [ $NVT_PRJCFG_CFG == "Linux" ]; then
		add_lunch_toolchain_combo arm-ca9-linux-gnueabihf-6.5
		add_lunch_toolchain_combo arm-ca9-linux-uclibcgnueabihf-6.5
	elif [ $NVT_PRJCFG_CFG == "rtos" ]; then
		add_lunch_toolchain_combo gcc-6.5-newlib-2.4-2019.11-arm-ca9-eabihf
	else
		echo -e "\e[1;45mERROR: We can't find your OS type!!!!!\r\n";
	fi
}


#####################################################################################################################
#
#	Kernel upgrade
#
#####################################################################################################################
function kernel_upgrade()
{
	export KERNELDIR=${LINUX_BUILD_BSP}/linux-4.19
}

#####################################################################################################################
#
#	Uboot upgrade
#
#####################################################################################################################
function uboot_upgrade()
{
	export UBOOT_DIR=${LINUX_BUILD_BSP}/u-boot-2019.04
}

#####################################################################################################################
#
#	To config the codebase system environmenr parameters
#
#####################################################################################################################
function set_stuff_for_environment()
{
	chk_for_the_same_codebase
	ret=$?
	if [ -z $NVT_PRJCFG_CFG ] || [ $ret -ne 1 ] ; then
		NVT_PRJCFG_CFG=$DEFAULT_NVT_ACTIVE_PROJ
	fi
	export LINUX_BUILD_TOP=$PWD
	export LINUX_BUILD_BSP=${LINUX_BUILD_TOP}/BSP
	export LINUX_BUILD_CODE=${LINUX_BUILD_TOP}/code
	export ROOTFS_DIR=${LINUX_BUILD_BSP}/root-fs
	export UBOOT_DIR=${LINUX_BUILD_BSP}/u-boot
	export NUTTX_DIR=${LINUX_BUILD_BSP}/nuttx
	export OPTEE_DIR=${LINUX_BUILD_BSP}/optee
	if [ $NVT_PRJCFG_CFG == "Linux" ]; then
		export KERNELDIR=${LINUX_BUILD_BSP}/linux-kernel
	elif [ $NVT_PRJCFG_CFG == "rtos" ]; then
		export KERNELDIR=${LINUX_BUILD_BSP}/rtos/amazon-freertos
	fi
	export BUSYBOX_DIR=${LINUX_BUILD_BSP}/busybox
	export TOYBOX_DIR=${LINUX_BUILD_BSP}/toybox
	export APP_DIR=${LINUX_BUILD_CODE}/application
	export LIBRARY_DIR=${LINUX_BUILD_CODE}/lib
	export INCLUDE_DIR=${LINUX_BUILD_CODE}/lib/include
	export NVT_HDAL_DIR=${LINUX_BUILD_CODE}/hdal
	export NVT_VOS_DIR=${LINUX_BUILD_CODE}/vos
	export NVT_RTOS_MAIN_DIR=${LINUX_BUILD_CODE}/rtos-main
	export SAMPLE_DIR=${LINUX_BUILD_CODE}/sample

	if [ $NVT_PRJCFG_CFG == "rtos" ]; then
		if [ ${RTOS_CPU_TYPE} == "cortex-a9" ]; then
			export NVT_DRIVER_DIR=${LINUX_BUILD_CODE}/driver/na51055
		else
			export NVT_DRIVER_DIR=${LINUX_BUILD_CODE}/driver/na51000
		fi
	else
		export NVT_DRIVER_DIR=${LINUX_BUILD_CODE}/driver
	fi
	export TOOLS_DIR=${LINUX_BUILD_TOP}/tools
	export BUILD_DIR=${LINUX_BUILD_TOP}/build
	export SHELL=/bin/bash
	export MAKE=${BUILD_DIR}/nvt-tools/make-4.1
	export OUTPUT_DIR=${LINUX_BUILD_TOP}/output
	export LOGS_DIR=${LINUX_BUILD_TOP}/logs
	export CONFIG_DIR=${LINUX_BUILD_TOP}/configs
	export NVT_DSP_DIR=${LINUX_BUILD_TOP}/dsp
	export NVT_LINUX_VER="4.19.91"
	if [ -z $NVT_CROSS ]; then
		export NVT_CROSS=${DEFAULT_NVT_CROSS}
	fi
	export NVT_MULTI_CORES_FLAG=-j`grep -c ^processor /proc/cpuinfo`
	setpaths
	setsymbolic
}

#####################################################################################################################
#
#	To config the toolchain path and compile cflags
#
#####################################################################################################################
function setpath_toolchain_config()
{
	if [ -z $NVT_PRJCFG_CFG ]; then
		echo -e "\e[1;45mERROR: We can't find your OS type in setpath toolchain config!!!!!\r\n"
		return;
	fi
	if [ $NVT_PRJCFG_CFG == "Linux" ]; then
		# default cross toolchain is glibc
		if [ -z "$NVT_CROSS" ] || [ "$NVT_CROSS" == "arm-ca9-linux-gnueabihf-6.5" ]; then
			export NVT_CROSS=arm-ca9-linux-gnueabihf-6.5
			if [ -d /opt/ivot/$NVT_CROSS ]; then
				export CROSS_TOOLCHAIN_PATH=/opt/ivot/${NVT_CROSS};
			elif [ -d /opt/arm/$NVT_CROSS ]; then
				export CROSS_TOOLCHAIN_PATH=/opt/arm/${NVT_CROSS};
			else
				export CROSS_TOOLCHAIN_PATH=/opt/${NVT_CROSS};
			fi
			export CROSS_TOOLCHAIN_BIN_PATH=${CROSS_TOOLCHAIN_PATH}/usr/bin
			export NVT_HOST=arm-ca9-linux-gnueabihf
			export SYSROOT_PATH=${CROSS_TOOLCHAIN_PATH}/usr/${NVT_HOST}/sysroot
			export CROSS_COMPILE=${CROSS_TOOLCHAIN_BIN_PATH}/${NVT_HOST}-
		elif [ "$NVT_CROSS" == "arm-ca9-linux-uclibcgnueabihf-6.5" ]; then
			export NVT_CROSS=arm-ca9-linux-uclibcgnueabihf-6.5
			if [ -d /opt/ivot/$NVT_CROSS ]; then
				export CROSS_TOOLCHAIN_PATH=/opt/ivot/${NVT_CROSS};
			elif [ -d /opt/arm/$NVT_CROSS ]; then
				export CROSS_TOOLCHAIN_PATH=/opt/arm/${NVT_CROSS};
			else
				export CROSS_TOOLCHAIN_PATH=/opt/${NVT_CROSS};
			fi
			export CROSS_TOOLCHAIN_BIN_PATH=${CROSS_TOOLCHAIN_PATH}/usr/bin
			export NVT_HOST=arm-linux
			export SYSROOT_PATH=${CROSS_TOOLCHAIN_PATH}/usr/arm-ca9-linux-uclibcgnueabihf/sysroot
			export CROSS_COMPILE=${CROSS_TOOLCHAIN_BIN_PATH}/${NVT_HOST}-
		elif [ "$NVT_CROSS" == "arm-ca53-linux-gnueabihf-6.5" ]; then
			export NVT_CROSS=arm-ca53-linux-gnueabihf-6.5
			if [ -d /opt/ivot/$NVT_CROSS ]; then
				export CROSS_TOOLCHAIN_PATH=/opt/ivot/${NVT_CROSS};
			elif [ -d /opt/arm/$NVT_CROSS ]; then
				export CROSS_TOOLCHAIN_PATH=/opt/arm/${NVT_CROSS};
			else
				export CROSS_TOOLCHAIN_PATH=/opt/${NVT_CROSS};
			fi
			export CROSS_TOOLCHAIN_BIN_PATH=${CROSS_TOOLCHAIN_PATH}/usr/bin
			export NVT_HOST=arm-ca53-linux-gnueabihf
			export SYSROOT_PATH=${CROSS_TOOLCHAIN_PATH}/usr/${NVT_HOST}/sysroot
			export CROSS_COMPILE=${CROSS_TOOLCHAIN_BIN_PATH}/${NVT_HOST}-
		else
			export NVT_CROSS=arm-ca53-linux-uclibcgnueabihf-6.4
			if [ -d /opt/ivot/$NVT_CROSS ]; then
				export CROSS_TOOLCHAIN_PATH=/opt/ivot/${NVT_CROSS};
			elif [ -d /opt/arm/$NVT_CROSS ]; then
				export CROSS_TOOLCHAIN_PATH=/opt/arm/${NVT_CROSS};
			else
				export CROSS_TOOLCHAIN_PATH=/opt/${NVT_CROSS};
			fi
			export CROSS_TOOLCHAIN_BIN_PATH=${CROSS_TOOLCHAIN_PATH}/usr/bin
			export NVT_HOST=arm-ca53-linux-uclibcgnueabihf
			export SYSROOT_PATH=${CROSS_TOOLCHAIN_PATH}/usr/${NVT_HOST}/sysroot
			export CROSS_COMPILE=${CROSS_TOOLCHAIN_BIN_PATH}/${NVT_HOST}-
		fi
		export UBOOT_CROSS_COMPILE=${CROSS_COMPILE}
	# RTOS needs to have two toolchain setup: 1. freertos codebase 2. Uboot codebase.
	elif [ $NVT_PRJCFG_CFG == "rtos" ]; then
		export NVT_CROSS=gcc-6.5-newlib-2.4-2019.11-arm-ca9-eabihf
		if [ -d /opt/ivot/$NVT_CROSS ]; then
			export CROSS_TOOLCHAIN_PATH=/opt/ivot/${NVT_CROSS};
		else
			export CROSS_TOOLCHAIN_PATH=/opt/${NVT_CROSS};
		fi
		export CROSS_TOOLCHAIN_BIN_PATH=${CROSS_TOOLCHAIN_PATH}/bin
		export NVT_HOST=arm-eabihf
		export SYSROOT_PATH=${CROSS_TOOLCHAIN_PATH}/usr/${NVT_HOST}/sysroot
		export CROSS_COMPILE=${CROSS_TOOLCHAIN_BIN_PATH}/${NVT_HOST}-

		UBOOT_CROSS_COMPILE_NAME=arm-ca9-linux-gnueabihf-6.5
		UBOOT_CROSS_COMPILE_HOST=arm-ca9-linux-gnueabihf
		export UBOOT_CROSS_COMPILE_PATH=/opt/ivot/${UBOOT_CROSS_COMPILE_NAME}
		if [ -d ${UBOOT_CROSS_COMPILE_PATH} ]; then
			export UBOOT_CROSS_COMPILE=${UBOOT_CROSS_COMPILE_PATH}/usr/bin/${UBOOT_CROSS_COMPILE_HOST}-;
		else
			export UBOOT_CROSS_COMPILE_PATH=/opt/${UBOOT_CROSS_COMPILE_NAME}
			if [ ! -d ${UBOOT_CROSS_COMPILE_PATH} ]; then
				echo -e "\e[1;45mERROR: We can't find your toolchain path $UBOOT_CROSS_COMPILE_PATH in setpath toolchain config!!!!!\r\n"
			else
				export UBOOT_CROSS_COMPILE=$UBOOT_CROSS_COMPILE_PATH/usr/bin/${UBOOT_CROSS_COMPILE_HOST}-;
			fi
		fi
		if [ -z "`echo $LD_LIBRARY_PATH | grep ${UBOOT_CROSS_COMPILE_PATH}/usr/`" ]; then
			if [ ! -z "${LD_LIBRARY_PATH}" ]; then
				export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${UBOOT_CROSS_COMPILE_PATH}/usr/local/lib
			else
				export LD_LIBRARY_PATH=${UBOOT_CROSS_COMPILE_PATH}/usr/local/lib
			fi
		fi
	fi
	export LINUX_BUILD_PATH=${CROSS_TOOLCHAIN_PATH}/bin
	export PATH=${CROSS_TOOLCHAIN_BIN_PATH}:${PATH}
	export ARCH=arm
	#----------------------------------------------------------------------
	# Machine Dependent Options
	#----------------------------------------------------------------------
	# -march=armv8-a    : Generate code that will run on ARMV8
	# -mtune=cortex-a53 : Optimize for cortex-a53
	# -mfpu=neon-fp-armv8 : Do not use floating-point coprocessor instructions
	# -mfloat-abi=hard  : To indicate that NEON variables must be passed in general purpose registers
	# -march=armv7-a    : Generate code that will run on ARMV7
	# -mtune=cortex-a9  : Optimize for cortex-a9
	# -mfpu=neon        : Do not use floating-point coprocessor instructions, simd + vfpv3
	# -mfloat-abi=hard  : To indicate that NEON variables must be passed in general purpose registers
	#----------------------------------------------------------------------
	# C Language Options
	#----------------------------------------------------------------------
	# -fno-builtin  : Don't recognize built-in functions that do not begin with `__builtin_' as prefix
	# -ffreestanding: Assert that compilation takes place in a freestanding environment
	#----------------------------------------------------------------------
	# Code Generation Options
	#----------------------------------------------------------------------
	# -fno-common   : The compiler should place uninitialized global variables in the data section of the object file, rather than generating them as common blocks
	# -fshort-wchar : Override the underlying type for `wchar_t' to be `short unsigned int' instead of the default for the target.
	#----------------------------------------------------------------------
	if [ "$NVT_PRJCFG_CFG" == "Linux" ]; then
		export PLATFORM_CFLAGS="-march=armv7-a -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard -ftree-vectorize -fno-builtin -fno-common -Wformat=1 -D_BSP_NA51055_"
		export PLATFORM_CXXFLAGS="-march=armv7-a -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard -ftree-vectorize -fno-builtin -fno-common -Wformat=1 -D_BSP_NA51055_"
		export PLATFORM_AFLAGS="-march=armv7-a -mtune=cortex-a9 -mfpu=neon -D_BSP_NA51055_"
	elif [ "$NVT_PRJCFG_CFG" == "rtos" ]; then
		if [ "${RTOS_CPU_TYPE}" == "cortex-a9" ]; then
			export PLATFORM_CFLAGS="-march=armv7-a -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard -nostartfiles -Wall -Winline -Wno-missing-braces  -Wpointer-arith -Wsign-compare -Wstrict-prototypes -Wundef -Werror -fno-exceptions -fno-common -fno-optimize-sibling-calls  -fno-strict-aliasing -fshort-wchar -O2 -fPIC -ffunction-sections -fdata-sections -fno-omit-frame-pointer -D__FREERTOS -D_BSP_NA51055_ -I${KERNELDIR}/lib/include -I${KERNELDIR}/lib/include/private -I${KERNELDIR}/arch/arm/mach-nvt-na51055/include/mach"
			export PLATFORM_CXXFLAGS="-march=armv7-a -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard -nostartfiles -Wall -Winline -Wno-missing-braces  -Wpointer-arith -Wsign-compare -Wundef -Werror -fno-common -fno-optimize-sibling-calls  -fno-strict-aliasing -fshort-wchar -O2 -fPIC -ffunction-sections -fdata-sections -fno-omit-frame-pointer -D__FREERTOS -D_BSP_NA51055_ -I${KERNELDIR}/lib/include -I${KERNELDIR}/lib/include/private -I${KERNELDIR}/arch/arm/mach-nvt-na51055/include/mach"
			export PLATFORM_AFLAGS="-march=armv7-a -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard -nostartfiles -Werror -D_BSP_NA51055_"
		else
			export PLATFORM_CFLAGS="-march=armv8-a -mtune=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard -nostartfiles -Wall -Winline -Wno-missing-braces  -Wpointer-arith -Wsign-compare -Wstrict-prototypes -Wundef -Werror -fno-exceptions -fno-common -fno-optimize-sibling-calls  -fno-strict-aliasing -fshort-wchar -O2 -fPIC -ffunction-sections -fdata-sections -fno-omit-frame-pointer -D__FREERTOS -D_BSP_NA51000_ -I${KERNELDIR}/lib/include -I${KERNELDIR}/lib/include/private -I${KERNELDIR}/arch/arm/mach-nvt-na51055/include/mach"
			export PLATFORM_CXXFLAGS="-march=armv8-a -mtune=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard -nostartfiles -Wall -Winline -Wno-missing-braces  -Wpointer-arith -Wsign-compare -Wundef -Werror -fno-exceptions -fno-common -fno-optimize-sibling-calls  -fno-strict-aliasing -fshort-wchar -O2 -fPIC -ffunction-sections -fdata-sections -fno-omit-frame-pointer -D__FREERTOS -D_BSP_NA51000_ -I${KERNELDIR}/include -I${KERNELDIR}/arch/arm/mach-nvt-na51055/include/mach"
			export PLATFORM_AFLAGS="-march=armv8-a -mtune=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard -nostartfiles -Werror -D_BSP_NA51000_"
		fi
	fi

	if [ "$NVT_FPGA" == "ON" ]; then
		export PLATFORM_CFLAGS="${PLATFORM_CFLAGS} -D_NVT_FPGA_"
		export PLATFORM_AFLAGS="${PLATFORM_AFLAGS} -D_NVT_FPGA_"
	fi
	if [ "$NVT_EMULATION" == "ON" ]; then
		export PLATFORM_CFLAGS="${PLATFORM_CFLAGS} -D_NVT_EMULATION_"
		export PLATFORM_AFLAGS="${PLATFORM_AFLAGS} -D_NVT_EMULATION_"
	fi
	if [ "$NVT_RUN_CORE2" == "ON" ]; then
		export PLATFORM_CFLAGS="${PLATFORM_CFLAGS} -D_NVT_RUN_CORE2_"
		export PLATFORM_AFLAGS="${PLATFORM_AFLAGS} -D_NVT_RUN_CORE2_"
	fi
}

#####################################################################################################################
#
#	To config the export includes NVT_GCOV and NVT_KGCOV for Code Coverage tool
#
#####################################################################################################################
function set_gcov()
{
	export NVT_GCOV="-fprofile-arcs -ftest-coverage -lgcov --coverage"
	export NVT_KGCOV="GCOV_PROFILE=y"
}
