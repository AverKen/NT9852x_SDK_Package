############################################################################
#
# Makefile -- Top level makefile.
#
# Copyright (c) 2016, Novatek
#
############################################################################
# common
MULTI_CORES ?= $(shell grep -c ^processor /proc/cpuinfo)
SHELL = /bin/bash
PYTHON := python
PWD = $(shell pwd)

# nvt modelconfig
$(shell cd ${CONFIG_DIR}; make gen_dtb; make gen_modelcfg > /dev/null 2>&1;)
include $(NVT_PRJCFG_MODEL_CFG)
-include $(BUILD_DIR)/definitions.mk

# kernel & modules
CUSTBOARDCONFIG := $(strip $(shell echo $(NVT_PRJCFG_MODEL_CFG) | grep NVT_CFG_KERNEL_CFG | awk -F'=' '{print $$NF;}'))
ifeq ($(EMBMEM), EMBMEM_SPI_NOR)
#BOARDCONFIG := $(shell if [ ! -z $(NVT_CFG_KERNEL_CFG) ]; then echo $(NVT_CFG_KERNEL_CFG); else echo na51055_evb_defconfig_nor_debug; fi)
BOARDCONFIG := $(shell if [ ! -z $(NVT_CFG_KERNEL_CFG) ]; then echo $(NVT_CFG_KERNEL_CFG); else echo na51055_evb_defconfig_nor_release; fi)
else ifeq ($(EMBMEM), EMBMEM_EMMC)
#BOARDCONFIG := $(shell if [ ! -z $(NVT_CFG_KERNEL_CFG) ]; then echo $(NVT_CFG_KERNEL_CFG); else echo na51055_evb_defconfig_emmc_debug; fi)
BOARDCONFIG := $(shell if [ ! -z $(NVT_CFG_KERNEL_CFG) ]; then echo $(NVT_CFG_KERNEL_CFG); else echo na51055_evb_defconfig_emmc_release; fi)
else
#for flash
#BOARDCONFIG := $(shell if [ ! -z $(NVT_CFG_KERNEL_CFG) ]; then echo $(NVT_CFG_KERNEL_CFG); else echo na51055_evb_defconfig_debug; fi)
BOARDCONFIG := $(shell if [ ! -z $(NVT_CFG_KERNEL_CFG) ]; then echo $(NVT_CFG_KERNEL_CFG); else echo na51055_evb_defconfig_release; fi)
endif

ifeq ($(EMBMEM), EMBMEM_SPI_NAND)
UBOOT_DEFCONFIG := $(shell if [ ! -z $(NVT_CFG_UBOOT_CFG) ]; then echo $(NVT_CFG_UBOOT_CFG); else echo nvt-na51055_nand_defconfig; fi)
else ifeq ($(EMBMEM), EMBMEM_SPI_NOR)
UBOOT_DEFCONFIG := $(shell if [ ! -z $(NVT_CFG_UBOOT_CFG) ]; then echo $(NVT_CFG_UBOOT_CFG); else echo nvt-na51055_nor_defconfig; fi)
else ifeq ($(EMBMEM), EMBMEM_NONE)
UBOOT_DEFCONFIG := $(shell if [ ! -z $(NVT_CFG_UBOOT_CFG) ]; then echo $(NVT_CFG_UBOOT_CFG); else echo nvt-na51055_nand_defconfig; fi)
else
UBOOT_DEFCONFIG := $(shell if [ ! -z $(NVT_CFG_UBOOT_CFG) ]; then echo $(NVT_CFG_UBOOT_CFG); else echo nvt-na51055_emmc_defconfig; fi)
endif

KERNEL_OUTPUT := $(KERNELDIR)
KERNEL_IMGNAME := uImage.bin
KERNEL_RAMDISK_IMGNAME := uImage.ramdisk.bin
KERNEL_HEADER := linux_header
ENCRYPT_KERNEL_IMGNAME := uImage.encrypted.bin
NUTTX_IMGNAME := nuttx.bin
PINMUX_CONFIG:= nvt-na51000-top.dtsi
GPIO_CONFIG:= nvt-na51000-gpio.dtsi

# optee
OPTEE_IMGNAME := tee-pager.bin
ENCRYPT_OPTEE_IMGNAME := tee.encrypted.bin

# uboot
UBOOT_IMGNAME := u-boot.bin
ENCRYPT_UBOOT_IMGNAME := u-boot.encrypted.bin


# busybox
BUSYBOX_CFG := busybox_cfg_full
#BUSYBOX_CFG := busybox_cfg_small

# toybox
TOYBOX_CFG := toybox_cfg_full
#TOBOX_CFG := toybox_cfg_small

# log
log_stdout = echo -e "\e[1;44m$@: Build start\e[0m"; \
		$(1) 2> >(tee -a $(LOGS_DIR)/$@.log_err) > >(tee -a $(LOGS_DIR)/$@.log); \
		ret=$$PIPESTATUS; \
		echo -e "\e[1;44m$@: Build finish\e[0m"; \
		if [ -e $(LOGS_DIR)/$@.log_err ]; then cat $(LOGS_DIR)/$@.log_err >&2; fi; \
		if [ -z "`cat $(LOGS_DIR)/$@.log_err`" ]; then \
			rm $(LOGS_DIR)/$@.log_err; \
		fi; \
		exit $$ret;

log_remove = if [ ! -e $(LOGS_DIR) ]; then mkdir $(LOGS_DIR); fi; if [ -e $(LOGS_DIR)/$@.log ]; then rm $(LOGS_DIR)/$@.log; fi; if [ -e $(LOGS_DIR)/$@.log_err ]; then rm $(LOGS_DIR)/$@.log_err; fi;

check_copy = for n in $(1); do if [ -f $$n ]; then cp -av $$n $(2); fi; done;

# linux rtc driver
export CONFIG_NVT_RTC_CLOCK = $(shell echo $(CLOCK))

# misc
BUILD_COMPLETE_STRING ?= $(shell date "+%a, %d %b %Y %T %z")
UID := $(shell id -u)
GID := $(shell id -g)
removeimg = $(foreach a,$(1),$(if $(wildcard $(a)),rm -rf $(a)))
unexport KBUILD_OUTPUT

# make global flags
MAKE_QUIET_FLAGS = --no-print-directory

# check path existing for build all
BUILD_ALL = cfg
ifeq ($(NVT_PRJCFG_CFG), Linux)
BUILD_ALL += busybox linux modules
CLEAN_ALL += busybox_clean tools_clean
else ifeq ($(NVT_PRJCFG_CFG), rtos)
BUILD_ALL += rtos
CLEAN_ALL += rtos_clean
endif
ifneq ($(wildcard $(NVT_VOS_DIR)/source/Makefile),)
BUILD_ALL += vos
CLEAN_ALL += vos_clean
endif
ifneq ($(wildcard $(NVT_HDAL_DIR)/Makefile),)
BUILD_ALL += hdal
CLEAN_ALL += hdal_clean
endif
ifeq ($(NVT_PRJCFG_CFG), Linux)
CLEAN_ALL += linux_clean
endif
ifneq ($(wildcard $(NUTTX_DIR)/Makefile),)
BUILD_ALL += nuttx
CLEAN_ALL += nuttx_clean
endif
ifneq ($(wildcard $(OPTEE_DIR)/optee_client/Makefile),)
#optee_client clean depends on optee_os's some output mk
CLEAN_ALL += optee_client_clean
endif
ifneq ($(wildcard $(OPTEE_DIR)/optee_os/Makefile),)
BUILD_ALL += optee_os
CLEAN_ALL += optee_os_clean
endif
ifeq ($(ENCRYPT_OPTEE), ENCRYPT_OPTEE_ON)
BUILD_ALL += optee_os_encrypt
CLEAN_ALL += optee_os_encrypt_clean
endif
ifneq ($(wildcard $(NVT_DRIVER_DIR)/Makefile),)
BUILD_ALL += driver
CLEAN_ALL += driver_clean
endif
ifneq ($(wildcard $(LIBRARY_DIR)/Makefile),)
BUILD_ALL += library
CLEAN_ALL += library_clean
endif
ifneq ($(wildcard $(OPTEE_DIR)/optee_client/Makefile),)
BUILD_ALL += optee_client
endif
ifneq ($(wildcard $(APP_DIR)/Makefile),)
BUILD_ALL += app
CLEAN_ALL += app_clean
endif
ifeq ($(EMBMEM), EMBMEM_EMMC)
ifeq ($(NVT_PRJCFG_CFG), Linux)
BUILD_ALL += mbr
CLEAN_ALL += mbr_clean
endif
endif
ifneq ($(wildcard $(UBOOT_DIR)/Makefile),)
BUILD_ALL += uboot
CLEAN_ALL += uboot_clean
ifeq ($(ENCRYPT_UBOOT), ENCRYPT_UBOOT_ON)
BUILD_ALL += uboot_encrypt
CLEAN_ALL += uboot_encrypt_clean
endif
endif
ifeq ($(ENCRYPT_KERNEL), ENCRYPT_KERNEL_ON)
BUILD_ALL += linux_encrypt
CLEAN_ALL += linux_encrypt_clean
endif
ifneq ($(wildcard $(SAMPLE_DIR)/Makefile),)
BUILD_ALL += sample
CLEAN_ALL += sample_clean
endif
BUILD_ALL += post
CLEAN_ALL += post_clean
ifeq ($(NVT_PRJCFG_CFG), Linux)
BUILD_ALL += rootfs
CLEAN_ALL += rootfs_clean
endif
BUILD_ALL += pack
CLEAN_ALL += pack_clean cfg_clean

all: $(BUILD_ALL)
	@echo "Finish generating images at $(BUILD_COMPLETE_STRING)"
	@$(call update_modelcfg_to_build)

.PHONY: rootfs uboot linux modules tools app sample

pack:
	@$(call gen_nvt_pack)

checkenv:
	@if [ -z $(LINUX_BUILD_TOP) ]; then \
		echo -e "\r\nERROR :Please source build/envsetup.sh in NA51000_BSP firstly to have auto copyso function\r\n"; \
		exit 1; \
	fi
	@if [ $(PWD) != $(LINUX_BUILD_TOP) ]; then \
		echo -e "\r\nERROR: Current path is not the same as the environment path ("$(LINUX_BUILD_TOP)")\r\n"; \
		exit 1; \
	fi
	@if [ ! -e $(OUTPUT_DIR) ]; then \
		mkdir $(OUTPUT_DIR); \
	fi
ifeq ($(NVT_PRJCFG_CFG), Linux)
	@# Generate etc link
	make -C ${ROOTFS_DIR} gen_etc
endif

checkrootfs:
	@if [ ! -f $(ROOTFS_DIR)/rootfs/bin/busybox ] || [ ! -f $(ROOTFS_DIR)/rootfs/lib/libc.so.0 ] && [ ! -f $(ROOTFS_DIR)/rootfs/lib/libc.so.6 ]; then \
		echo -e "\r\nERROR :Please make busybox & rootfs firstly\r\n"; \
		exit 1; \
	fi

chk_unix: checkenv
	@echo "##### check unix line delimiter format #####"
	@$(BUILD_DIR)/nvt-tools/recursive_dir -t $(LINUX_BUILD_TOP)/code --exclude-ext .o .a .bin .axf .7z .srec .ttl .png .sln .user .filters .vcxproj .sym .bat --exclude-dir .svn .git libxml2-2.9.3 pattern

dep:
	@$(call make_dep_by_modelselect)

linux: checkenv
	@echo BOARDCONFIG = $(BOARDCONFIG)
	@cp $(KERNELDIR)/arch/$(ARCH)/configs/$(BOARDCONFIG) $(KERNELDIR)/.config
	@echo "##### Build kernel #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(KERNELDIR) uImage -j$(MULTI_CORES))
ifeq ($(NVT_LINUX_COMPRESS), NVT_LINUX_COMPRESS_LZMA)
	@$(BUILD_DIR)/nvt-tools/bfc c lzma $(KERNELDIR)/arch/$(ARCH)/boot/Image $(OUTPUT_DIR)/$(KERNEL_IMGNAME) 0 0 -align
else ifeq ($(NVT_LINUX_COMPRESS), NVT_LINUX_COMPRESS_LZ77)
	@$(BUILD_DIR)/nvt-tools/bfc c lz $(KERNELDIR)/arch/$(ARCH)/boot/Image $(OUTPUT_DIR)/$(KERNEL_IMGNAME) 0 0 -align
else ifeq ($(NVT_LINUX_COMPRESS), NVT_LINUX_COMPRESS_GZ)
	@$(BUILD_DIR)/nvt-tools/bfc c gz $(KERNELDIR)/arch/$(ARCH)/boot/Image $(OUTPUT_DIR)/$(KERNEL_IMGNAME) 0 0 -align
else ifeq ($(NVT_LINUX_COMPRESS), NVT_LINUX_COMPRESS_NONE)
	@mkimage -A arm -O linux -C none -T multi -a 0x00008000 -e 0x00008000 -n Linux-$(NVT_LINUX_VER) -d $(KERNELDIR)/arch/$(ARCH)/boot/Image $(OUTPUT_DIR)/$(KERNEL_IMGNAME)
else
	@cp -afL $(KERNELDIR)/arch/$(ARCH)/boot/uImage $(OUTPUT_DIR)/$(KERNEL_IMGNAME)
endif

linuxram: checkenv checkrootfs
	@echo BOARDCONFIG = $(BOARDCONFIG)
	@cp $(KERNELDIR)/arch/$(ARCH)/configs/$(BOARDCONFIG) $(KERNELDIR)/.config
	@echo "##### Build kernel #####"
	@$(call log_remove)
	@$(call log_stdout, cd $(KERNELDIR); sed -i 's/CONFIG_INITRAMFS_SOURCE=\"\"/CONFIG_INITRAMFS_SOURCE=\"$(shell echo $(ROOTFS_DIR)| sed 's/[\/ ]/\\&/g')\/rootfs\"/g' .config)
	@$(call log_stdout, cd $(KERNELDIR); echo -e "CONFIG_INITRAMFS_ROOT_UID=0\nCONFIG_INITRAMFS_ROOT_GID=0" >> .config)
	@$(call log_stdout, make -C $(KERNELDIR) uImage -j$(MULTI_CORES))
	@cp -afL $(KERNELDIR)/arch/$(ARCH)/boot/uImage $(OUTPUT_DIR)/$(KERNEL_RAMDISK_IMGNAME)

nuttx: checkenv
	@echo "##### Build secure OS (nuttx) #####"
	@$(call log_remove)
	@make -C $(NUTTX_DIR) 2>&1 | tee -a $(LOGS_DIR)/$@.log; make -C $(NUTTX_DIR) install 2>&1 | tee -a $(LOGS_DIR)/$@.log
	@$(BUILD_DIR)/nvt-tools/encrypt_bin SUM $(NUTTX_DIR)/bin/$(NUTTX_IMGNAME) 0x150 sec51055
	@cp -afL $(NUTTX_DIR)/bin/$(NUTTX_IMGNAME) $(OUTPUT_DIR)/

#0x16C: bin info (0x100) + crc offset(0x50) + tee header(0x1C)
optee_os: checkenv
	@echo "##### Build secure OS (optee kernel) #####"
	@$(call log_remove)
	@CROSS_PREFIX=${NVT_HOST} PLATFORM=novatek PLATFORM_FLAVOR=na51055 make -C $(OPTEE_DIR)/optee_os CFG_TEE_CORE_LOG_LEVEL=3 CFG_NS_ENTRY_ADDR=$(BOARD_UBOOT_ADDR) -j$(MULTI_CORES) 2>&1 | tee -a $(LOGS_DIR)/$@.log;
	@$(BUILD_DIR)/nvt-tools/encrypt_bin SUM $(OPTEE_DIR)/optee_os/out/arm-plat-novatek/core/$(OPTEE_IMGNAME) 0x150 te51055
	@cp -afL $(OPTEE_DIR)/optee_os/out/arm-plat-novatek/core/$(OPTEE_IMGNAME) $(OUTPUT_DIR)

optee_os_encrypt:
	#$(BUILD_DIR)/nvt-tools/encrypt_uboot $(OPTEE_DIR)/optee_os/out/arm-plat-novatek/core/$(OPTEE_IMGNAME) $(OPTEE_DIR)/optee_os/out/arm-plat-novatek/core/$(ENCRYPT_OPTEE_IMGNAME) $(CONFIG_DIR)/cfg_gen/aes.txt $(ENCRYPT_MSG_DISPLAY) 1024
	$(BUILD_DIR)/nvt-tools/encrypt_sign_tool 0 $(CONFIG_DIR)/cfg_gen/public $(CONFIG_DIR)/cfg_gen/private $(CONFIG_DIR)/cfg_gen/aes_key.txt $(OPTEE_DIR)/optee_os/out/arm-plat-novatek/core/$(OPTEE_IMGNAME) $(OPTEE_DIR)/optee_os/out/arm-plat-novatek/core/$(ENCRYPT_OPTEE_IMGNAME)
	@cp -af $(OPTEE_DIR)/optee_os/out/arm-plat-novatek/core/$(ENCRYPT_OPTEE_IMGNAME) $(OUTPUT_DIR)

optee_client: checkenv
	@echo "##### Build secure OS (optee client) #####"
	@$(call log_remove)
	@make -C $(OPTEE_DIR)/optee_client 2>&1 | tee -a $(LOGS_DIR)/$@.log; make -C $(OPTEE_DIR)/optee_client install 2>&1 | tee -a $(LOGS_DIR)/$@.log

modules: checkenv
	@if [ ! -e $(KERNELDIR)/vmlinux ]; then \
		echo "##### Please run \"make linux\" firstly #####";\
		exit 1;\
	fi
	@$(call log_remove)
	@$(call log_stdout, make -C $(KERNELDIR) modules -j$(MULTI_CORES))
	@echo "##### Build modules #####"
	@rm -rf $(KERNELDIR)/_install_modules/
	@$(call log_stdout, make -C $(KERNELDIR) INSTALL_MOD_PATH=$(KERNELDIR)/_install_modules/ modules_install -j$(MULTI_CORES))
	# copy kernel objects to rootfs
	@echo "##### Copy kernel objects to rootFS #####"
	@cp -af $(KERNELDIR)/_install_modules/lib/modules $(ROOTFS_DIR)/rootfs/lib/

driver: checkenv
ifeq ($(NVT_PRJCFG_CFG), Linux)
	@if [ ! -e $(KERNELDIR)/_install_modules ]; then \
		echo "##### Please run \"make modules\" firstly #####";\
		exit 1;\
	fi
endif
	@echo "##### Build drivers #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(NVT_DRIVER_DIR) modules $(MAKE_QUIET_FLAGS))
	@$(call log_stdout, make -C $(NVT_DRIVER_DIR) modules_install $(MAKE_QUIET_FLAGS))
ifeq ($(NVT_PRJCFG_CFG), Linux)
	@echo "##### Copy modules to rootFS #####"
	cp -af $(KERNELDIR)/_install_modules/lib/modules $(ROOTFS_DIR)/rootfs/lib/
endif

rtos: checkenv
	@echo "##### Build rtos #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(KERNELDIR)/demos/novatek/na51055/source $(MAKE_QUIET_FLAGS))
	@$(call log_stdout, make -C $(KERNELDIR)/demos/novatek/na51055/source install $(MAKE_QUIET_FLAGS))

vos: checkenv
ifeq ($(NVT_PRJCFG_CFG), Linux)
	@if [ ! -e $(KERNELDIR)/_install_modules ]; then \
		echo "##### Please run \"make modules\" firstly #####";\
		exit 1;\
	fi
endif
	@echo "##### Build vos #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(NVT_VOS_DIR) $(MAKE_QUIET_FLAGS))
	@$(call log_stdout, make -C $(NVT_VOS_DIR) install $(MAKE_QUIET_FLAGS))
ifeq ($(NVT_PRJCFG_CFG), Linux)
	@echo "##### Copy kernel objects to rootFS #####"
	@cp -af $(KERNELDIR)/_install_modules/lib/modules $(ROOTFS_DIR)/rootfs/lib/
endif

hdal: checkenv
ifeq ($(NVT_PRJCFG_CFG), Linux)
	@if [ ! -e $(KERNELDIR)/_install_modules ]; then \
		echo "##### Please run \"make modules\" firstly #####";\
		exit 1;\
	fi
endif
	@echo "##### Build hdal #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(NVT_HDAL_DIR) $(MAKE_QUIET_FLAGS))
	@$(call log_stdout, make -C $(NVT_HDAL_DIR) install $(MAKE_QUIET_FLAGS))
	@$(call log_stdout, make -C $(NVT_HDAL_DIR) sample $(MAKE_QUIET_FLAGS))
	@$(call log_stdout, make -C $(NVT_HDAL_DIR) sample_install $(MAKE_QUIET_FLAGS))
	@$(call log_stdout, make -C $(NVT_HDAL_DIR) test $(MAKE_QUIET_FLAGS))
	@$(call log_stdout, make -C $(NVT_HDAL_DIR) test_install $(MAKE_QUIET_FLAGS))
ifeq ($(NVT_PRJCFG_CFG), Linux)
	@echo "##### Copy kernel objects to rootFS #####"
	@cp -af $(KERNELDIR)/_install_modules/lib/modules $(ROOTFS_DIR)/rootfs/lib/
endif

mbr: checkenv
	@echo "##### Build mbr #####"
	@$(call gen_mbr);

alg: checkenv
ifeq ($(NVT_PRJCFG_CFG), Linux)
	@if [ ! -e $(KERNELDIR)/_install_modules ]; then \
		echo "##### Please run \"make modules\" firstly #####";\
		exit 1;\
	fi
endif
	@echo "##### Build alg #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(NVT_HDAL_DIR)/vendor/alg $(MAKE_QUIET_FLAGS))
ifeq ($(NVT_PRJCFG_CFG), Linux)
	@echo "##### Copy kernel objects to rootFS #####"
	@cp -af $(KERNELDIR)/_install_modules/lib/modules $(ROOTFS_DIR)/rootfs/lib/
endif

dsp: checkenv
	@echo "##### Build dsp #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(NVT_DSP_DIR)/FreeRTOS/FreeRTOS_8.1.2_CEVA-XM4/CEVA_FreeRTOS $(MAKE_QUIET_FLAGS))
	@$(call log_stdout, make -C $(NVT_DSP_DIR)/FreeRTOS/FreeRTOS_8.1.2_CEVA-XM4/CEVA_FreeRTOS install $(MAKE_QUIET_FLAGS))

uboot: checkenv
	@echo "##### Build u-boot loader$(UBOOT_DEFCONFIG) #####"
	@$(call log_remove)
	@$(call log_stdout, CROSS_COMPILE=${UBOOT_CROSS_COMPILE} && make -C $(UBOOT_DIR) O="" distclean)
	@$(call log_stdout, CROSS_COMPILE=${UBOOT_CROSS_COMPILE} && make -C $(UBOOT_DIR) O="" $(UBOOT_DEFCONFIG))
	@$(call log_stdout, CROSS_COMPILE=${UBOOT_CROSS_COMPILE} && make -C $(UBOOT_DIR) O="" -j$(MULTI_CORES))
	@$(call log_stdout, CROSS_COMPILE=${UBOOT_CROSS_COMPILE} && make -C $(UBOOT_DIR) O="" env)
	@$(call log_stdout, CROSS_COMPILE=${UBOOT_CROSS_COMPILE} && make -C $(UBOOT_DIR) O="" examples)
	@$(BUILD_DIR)/nvt-tools/encrypt_bin SUM $(UBOOT_DIR)/u-boot.bin 0x350 ub51055
	@$(BUILD_DIR)/nvt-tools/bfc c lz $(UBOOT_DIR)/u-boot.bin $(UBOOT_DIR)/u-boot.lz.bin 0 0
	@cp -af $(UBOOT_DIR)/u-boot.bin $(UBOOT_DIR)/u-boot.lz.bin $(OUTPUT_DIR)/




uboot_encrypt: checkenv

#	$(BUILD_DIR)/nvt-tools/encrypt_uboot $(UBOOT_DIR)/u-boot.bin $(UBOOT_DIR)/$(ENCRYPT_UBOOT_IMGNAME) $(CONFIG_DIR)/cfg_gen/aes.txt $(ENCRYPT_MSG_DISPLAY) 1024
	$(BUILD_DIR)/nvt-tools/encrypt_sign_tool 0 $(CONFIG_DIR)/cfg_gen/public $(CONFIG_DIR)/cfg_gen/private $(CONFIG_DIR)/cfg_gen/aes_key.txt $(UBOOT_DIR)/u-boot.bin $(UBOOT_DIR)/$(ENCRYPT_UBOOT_IMGNAME)
	@cp -af $(UBOOT_DIR)/$(ENCRYPT_UBOOT_IMGNAME) $(OUTPUT_DIR)/


linux_encrypt: checkenv
	$(BUILD_DIR)/nvt-tools/encrypt_sign_tool 0 $(CONFIG_DIR)/cfg_gen/public $(CONFIG_DIR)/cfg_gen/private $(CONFIG_DIR)/cfg_gen/aes_key.txt $(OUTPUT_DIR)/$(KERNEL_IMGNAME) $(OUTPUT_DIR)/$(ENCRYPT_KERNEL_IMGNAME)

uboot_config: checkenv
	@echo "##### u-boot Menuconfig #####"
	@cp $(UBOOT_DIR)/configs/$(UBOOT_DEFCONFIG) $(UBOOT_DIR)/.config
	make -C $(UBOOT_DIR) O="" menuconfig
	@cp $(UBOOT_DIR)/.config $(UBOOT_DIR)/configs/$(UBOOT_DEFCONFIG)

busybox: checkenv
	@echo "##### Build busybox #####"
	cp $(BUSYBOX_DIR)/$(BUSYBOX_CFG) $(BUSYBOX_DIR)/.config
	@$(call log_remove)
	@$(call log_stdout, make -C $(BUSYBOX_DIR) -j$(MULTI_CORES))
	@$(call log_stdout, make -C $(BUSYBOX_DIR) -j$(MULTI_CORES) install)
	@cp -af $(BUSYBOX_DIR)/_install/* $(ROOTFS_DIR)/rootfs

toybox: checkenv
	@echo "##### Build toybox #####"
	cd $(TOYBOX_DIR)/; if [ ! -f generated/Config.probed ]; then ./scripts/genconfig.sh; fi
	cp $(TOYBOX_DIR)/$(TOYBOX_CFG) $(TOYBOX_DIR)/.config
	@$(call log_remove)
#	$(call removeimg,$(ROOTFS_DIR)/rootfs/bin/busybox)
	$(call remove_lost_symbolic, $(ROOTFS_DIR)/rootfs)
	@$(call log_stdout, CROSS_COMPILE="" make -C $(TOYBOX_DIR) -j$(MULTI_CORES))
#	@$(call log_stdout, cd $(TOYBOX_DIR)/mksh; CC=$(CC) bash ./Build.sh)
#	@$(call log_stdout, CROSS_COMPILE="" PREFIX=$(ROOTFS_DIR)/rootfs make -C $(TOYBOX_DIR) -j$(MULTI_CORES) install)
#	@$(call gen_toybox_symbolic, $(ROOTFS_DIR)/rootfs)

library: checkenv
	@echo "##### Build library #####"
	@$(call log_remove)
	@$(call log_stdout, make -C ${LIBRARY_DIR})
	@$(call log_stdout, make -C ${LIBRARY_DIR} install)

rootfs: checkenv
ifeq ($(NVT_PRJCFG_CFG), Linux)
	@echo "##### Build rootfs #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(ROOTFS_DIR))
	@$(call log_stdout, make -C $(ROOTFS_DIR) install)
endif

sample: checkenv
	@echo "##### Build device driver test #####"
	@$(call log_remove)
	@$(call log_stdout, make -C ${SAMPLE_DIR})
	@$(call log_stdout, make -C ${SAMPLE_DIR} install)

app: checkenv
	@echo "##### Build app #####"
	@$(call log_remove)
	@$(call log_stdout, make -C ${APP_DIR} $(MAKE_QUIET_FLAGS))
	@$(call log_stdout, make -C ${APP_DIR} install $(MAKE_QUIET_FLAGS))
ifeq ($(NVT_PRJCFG_CFG), rtos)
	@cp ${APP_DIR}/output/*.bin $(OUTPUT_DIR)
endif

tools: checkenv
	@echo "##### Build tools #####"
	@cd ${TOOLS_DIR}; make; make install;

cfg: checkenv
	@echo "##### Build config #####"
	@if [ -f build/nvt-tools/nvt_pinctrl_tool/$(PINMUX_CONFIG) ]; then \
		MODEL=`echo $(NVT_PRJCFG_MODEL_CFG) | awk -F'/' '{print $$(NF-1)}' | awk -F'cfg_' '{print $$NF}'`; \
		cp build/nvt-tools/nvt_pinctrl_tool/$(PINMUX_CONFIG) configs/$(NVT_PRJCFG_CFG)/cfg_$$MODEL/; \
	fi
	@if [ -f build/nvt-tools/nvt_pinctrl_tool/$(GPIO_CONFIG) ]; then \
		MODEL=`echo $(NVT_PRJCFG_MODEL_CFG) | awk -F'/' '{print $$(NF-1)}' | awk -F'cfg_' '{print $$NF}'`; \
		cp build/nvt-tools/nvt_pinctrl_tool/$(GPIO_CONFIG) configs/$(NVT_PRJCFG_CFG)/cfg_$$MODEL/; \
	fi
	@$(call log_remove)
	@$(call log_stdout, cd ${CONFIG_DIR}; make; make install)

post: checkenv
	@echo "##### run postprocessing script #####";
	@if [ ! -z $(NVT_MAKE_POST) ] && [ -f $(dir $(NVT_PRJCFG_MODEL_CFG))/$(NVT_MAKE_POST) ] ; then \
		sh $(dir $(NVT_PRJCFG_MODEL_CFG))/$(NVT_MAKE_POST); \
	fi

publish: checkenv
	@echo "##### remove some sources for publish #####";
	@find $(LINUX_BUILD_TOP) -name publish.json -print0 | xargs -n 1 -0 build/nvt-tools/publish.py -s -j

busybox_config: checkenv
	@echo "##### busybox Menuconfig #####"
	cp $(BUSYBOX_DIR)/$(BUSYBOX_CFG) $(BUSYBOX_DIR)/.config
	make -C $(BUSYBOX_DIR) -j$(MULTI_CORES) menuconfig
	cp $(BUSYBOX_DIR)/.config $(BUSYBOX_DIR)/$(BUSYBOX_CFG)

toybox_config: checkenv
	@echo "##### toybox Menuconfig #####"
	cd $(TOYBOX_DIR)/; if [ ! -f generated/Config.probed ]; then ./scripts/genconfig.sh; fi
	cp $(TOYBOX_DIR)/$(TOYBOX_CFG) $(TOYBOX_DIR)/.config
	CROSS_COMPILE="" make -C $(TOYBOX_DIR) -j$(MULTI_CORES) menuconfig
	cp $(TOYBOX_DIR)/.config $(TOYBOX_DIR)/$(TOYBOX_CFG)

linux_config: checkenv
	@echo "##### linux kernel Menuconfig #####"
	@cp -ap $(KERNELDIR)/arch/$(ARCH)/configs/$(BOARDCONFIG) $(KERNEL_OUTPUT)/.config
	@make -C $(KERNELDIR) menuconfig
	@cp $(KERNEL_OUTPUT)/.config $(KERNELDIR)/arch/$(ARCH)/configs/$(BOARDCONFIG)

linux_config_gcov: checkenv
	@echo "##### linux kernel Menuconfig for gcov #####"
	@cd $(KERNELDIR); \
	echo -e "CONFIG_GCOV_KERNEL=y" > gcov.cfg; \
	KCONFIG_CONFIG=./arch/$(ARCH)/configs/$(BOARDCONFIG) \
	./scripts/kconfig/merge_config.sh $(KERNELDIR)/arch/$(ARCH)/configs/$(BOARDCONFIG) gcov.cfg; \
	rm gcov.cfg

nuttx_config: checkenv
	@echo "##### nuttx Menuconfig #####"
	@make -C $(NUTTX_DIR) config

linux_header: checkenv
	@echo "##### generate linux-kernel out of tree headers #####"
	@cp -ap $(KERNELDIR)/arch/$(ARCH)/configs/$(BOARDCONFIG) $(KERNEL_OUTPUT)/.config
	@$(call log_remove)
	@$(call log_stdout, make -C $(KERNELDIR) prepare)
	@$(call log_stdout, make -C $(KERNELDIR) scripts)

listpackage:
	make -C ${APP_DIR} listpackage

pack_clean:
	@$(call rm_nvt_pack)

linux_clean: checkenv
	@echo "##### Clean kernel related objects and config files #####"
	@$(call log_remove)
	@if [ -e $(KERNEL_OUTPUT) ]; then \
		$(call log_stdout, make -C $(KERNELDIR) mrproper -j4) \
	fi
	$(call removeimg,$(OUTPUT_DIR)/$(KERNEL_IMGNAME))

nuttx_clean: checkenv
	@echo "##### Clean secure OS (nuttx) #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(NUTTX_DIR) clean)
	$(call removeimg,$(OUTPUT_DIR)/$(NUTTX_IMGNAME))

optee_os_clean: checkenv
	@echo "##### Clean secure OS (optee_os) #####"
	@$(call log_remove)
	@$(call log_stdout, CROSS_PREFIX=${NVT_HOST} PLATFORM=novatek PLATFORM_FLAVOR=na51055 make -C $(OPTEE_DIR)/optee_os clean)
	$(call removeimg,$(OUTPUT_DIR)/$(OPTEE_IMGNAME))

optee_os_encrypt_clean: checkenv
	@echo "##### Clean encrypt optee_os #####"
	$(call removeimg,$(OUTPUT_DIR)/$(ENCRYPT_UBOOT_IMGNAME))

optee_client_clean: checkenv
	@echo "##### Clean secure OS (optee_client) #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(OPTEE_DIR)/optee_client clean)

rtos_clean: checkenv
	@echo "##### Clean rtos #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(KERNELDIR)/demos/novatek/na51055/source clean $(MAKE_QUIET_FLAGS))

vos_clean: checkenv
	@echo "##### Clean vos #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(NVT_VOS_DIR) clean $(MAKE_QUIET_FLAGS))

hdal_clean: checkenv
	@echo "##### Clean hdal #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(NVT_HDAL_DIR) clean $(MAKE_QUIET_FLAGS))

mbr_clean: checkenv
	@echo "##### Clean mbr #####"
	@rm -rf $(OUTPUT_DIR)/MBR*

alg_clean: checkenv
	@echo "##### Clean alg #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(NVT_HDAL_DIR)/vendor/alg clean $(MAKE_QUIET_FLAGS))

dsp_clean: checkenv
	@echo "##### Clean dsp #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(NVT_DSP_DIR)/FreeRTOS/FreeRTOS_8.1.2_CEVA-XM4/CEVA_FreeRTOS clean $(MAKE_QUIET_FLAGS))

driver_clean: checkenv
	@echo "##### Clean driver modules #####"
	@$(call log_remove)
	@$(call log_stdout, make -C $(NVT_DRIVER_DIR) clean)
ifeq ($(NVT_PRJCFG_CFG), Linux)
	@$(call removeimg,$(KERNEL_OUTPUT)/_install_modules/)
endif

uboot_clean: checkenv
	@echo "##### Clean u-boot loader #####"
	@$(call log_remove)
	@$(call log_stdout, make -C ${UBOOT_DIR} distclean)
	@$(call removeimg,$(UBOOT_DIR)/u-boot.bin $(UBOOT_DIR)/u-boot.lz.bin $(OUTPUT_DIR)/$(UBOOT_IMGNAME))

uboot_encrypt_clean: checkenv
	@echo "##### Clean encrypt u-boot loader #####"
	@$(call removeimg,$(OUTPUT_DIR)/$(ENCRYPT_UBOOT_IMGNAME))
linux_encrypt_clean: checkenv
	@echo "##### Clean encrypt linux #####"
	@$(call removeimg,$(OUTPUT_DIR)/$(ENCRYPT_RAMDISK_KERNEL_IMGNAME))
busybox_clean: checkenv
	@echo "##### Clean busybox #####"
	@$(call log_remove)
	@$(call log_stdout,make -C ${BUSYBOX_DIR} doc-clean; make -C ${BUSYBOX_DIR} distclean)

toybox_clean: checkenv
	@echo "##### Clean toybox #####"
	@$(call log_remove)
	@$(call log_stdout, CROSS_COMPILE="" make -C $(TOYBOX_DIR) -j$(MULTI_CORES) distclean)

library_clean: checkenv
	@echo "##### Clean library #####"
	@$(call log_remove)
	@$(call log_stdout, make -C ${LIBRARY_DIR} clean)

rootfs_clean: checkenv
	@echo "##### Clean rootfs #####"
	@$(call log_remove)
	@$(call log_stdout, make -C ${ROOTFS_DIR} clean)

sample_clean: checkenv
	@echo "##### Clean device driver test #####"
	@$(call log_remove)
	@$(call log_stdout, make -C ${SAMPLE_DIR} clean)

app_clean: checkenv
	@echo "##### Clean applications #####"
	@$(call log_remove)
	@$(call log_stdout, make -C ${APP_DIR} clean)

tools_clean: checkenv
	@echo "##### Clean tools #####"
	@cd ${TOOLS_DIR}; make clean;

cfg_clean: checkenv
	@echo "##### Clean config #####"
	@$(call log_remove)
	@$(call log_stdout, cd ${CONFIG_DIR}; make clean)

post_clean: checkenv
	@echo "##### run postprocessing clean script #####";
	@if [ ! -z $(NVT_MAKE_POST_CLEAN) ] && [ -f $(dir $(NVT_PRJCFG_MODEL_CFG))/$(NVT_MAKE_POST_CLEAN) ] ; then \
		sh $(dir $(NVT_PRJCFG_MODEL_CFG))/$(NVT_MAKE_POST_CLEAN); \
	fi

clean: $(CLEAN_ALL) rm_logs
	@rm -rf $(OUTPUT_DIR)
	@echo "make clean completed"

rm_logs:
	$(call removeimg,$(LOGS_DIR))

showenv:
	@echo $(PATH)

help:
	@echo "====================================================="
	@echo "make help             -> show make command info"
	@echo "make all              -> build all"
	@echo "make linux            -> build linux-kernel"
	@echo "make linuxram         -> build linux-kernel with ramdisk support"
	@echo "make modules          -> build built-in kernel modules"
	@echo "make driver           -> build NVT linux driver modules"
	@echo "make uboot            -> build loader(uboot)"
	@echo "make library          -> build library"
	@echo "make busybox          -> build busybox"
	@echo "make rootfs           -> build rootfs"
	@echo "make app              -> build applications"
	@echo "make tools            -> build tools"
	@echo "make sample           -> build sample code"
	@echo "make post             -> run postprocessing script"
	@echo "make pack             -> Generate nvtpack image"
	@echo "make publish          -> remove some sources for publish"
	@echo "====================================================="
	@echo "make linux_config     -> config linux-kernel"
	@echo "make linux_config_gcov-> modify kernel config for code coverage tool"
	@echo "make uboot_config     -> config uboot"
	@echo "make busybox_config   -> config busybox"
	@echo "make linux_header     -> generate linux-kernel out of tree headers"
	@echo "====================================================="
	@echo "make clean            -> clean all"
	@echo "make linux_clean      -> clean linux-kernel & built-in kernel modules"
	@echo "make driver_clean     -> clean NVT linux driver modules"
	@echo "make uboot_clean      -> clean loader(uboot)"
	@echo "make library_clean    -> clean library"
	@echo "make busybox_clean    -> clean busybox"
	@echo "make rootfs_clean     -> clean rootfs"
	@echo "make app_clean        -> clean applications"
	@echo "make tools_clean      -> clean tools"
	@echo "make sample_clean     -> clean sample code"
	@echo "make post_clean       -> run postprocessing clean script"
	@echo "make pack_clean       -> Remove nvtpack image"
	@echo "====================================================="

header:
	@echo "Create kernel headers for external driver building, please wait..."
	@cd ${KERNELDIR}; \
	mkdir -p ${KERNEL_HEADER}/arch; \
	mkdir -p ${KERNEL_HEADER}/include/config; \
	mkdir -p ${KERNEL_HEADER}/include/generated; \
	cp -rf arch/${ARCH} ${KERNEL_HEADER}/arch; \
	cp -a usr drivers include init Kbuild Makefile $(KERNEL_OUTPUT)/modules.order $(KERNEL_OUTPUT)/Module.symvers scripts $(KERNEL_OUTPUT)/.config ${KERNEL_HEADER}; \
	cp -a $(KERNEL_OUTPUT)/include/config/auto.conf ${KERNEL_HEADER}/include/config/; \
	cp -a $(KERNEL_OUTPUT)/include/generated/autoconf.h ${KERNEL_HEADER}/include/generated/; \
	find ${KERNEL_HEADER} -name "*.o" | xargs rm -rf; \
	find ${KERNEL_HEADER} -name "*.svn" | xargs rm -rf; \
	find ${KERNEL_HEADER}/arch -name "*.c" | xargs rm -rf; \
	find ${KERNEL_HEADER}/drivers -name "*.c" | xargs rm -rf; \
	find ${KERNEL_HEADER}/init -name "*.c" | xargs rm -rf; \
	tar -czvf $(OUTPUT_DIR)/${KERNEL_HEADER}.tgz ${KERNEL_HEADER}; \
	rm -rf ${KERNEL_HEADER}; \
	cd -;

header_clean:
	@echo "##### Clean header #####"
	@$(call log_remove)
	@$(call removeimg,$(OUTPUT_DIR)/${KERNEL_HEADER}.tgz)
