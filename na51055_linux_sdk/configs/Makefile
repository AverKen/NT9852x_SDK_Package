#include $(NVT_PRJCFG_MODEL_CFG)
NVT_CFG_DTS="nvt-na51055-evb"
#C_DEFINE_EXT = -DBIN_NAME='"$(BIN_NAME)"' \
#		-DEMBMEM='"$(EMBMEM)"'
DTC_VER=$(shell ver=`dtc -v | awk -F' ' '{print $$NF}' | awk -F'-' '{print $$(NF-1)}'`; echo "$$ver" | sed 's/[^a-zA-Z0-9]//g')
DTC_CFLAGS=$(shell echo "-W no-unit_address_format -W no-unit_address_vs_reg")

define gen_model_cfg_link
	MODEL=`echo $(NVT_PRJCFG_MODEL_CFG) | awk -F'/' '{print $$(NF-1)}'`;\
	if [ -f $(CONFIG_DIR)/$(NVT_PRJCFG_CFG)/$$MODEL/ModelConfig.mk ]; then \
		cd $(CONFIG_DIR); rm -rf cfg_gen; ln -s $(NVT_PRJCFG_CFG)/$$MODEL cfg_gen; \
	else \
		MODEL_EXT=`cat $(NVT_PRJCFG_MODEL_CFG) | grep MODELEXT | grep -v "#" | awk -F'=' '{print $$NF}' | awk -F'MODELEXT_' '{print $$NF}'`; \
		cd $(CONFIG_DIR); rm -rf cfg_gen; ln -s $$MODEL cfg_gen; \
		rm -rf $(CONFIG_DIR)/$(NVT_PRJCFG_CFG)/$$MODEL/MODELEXT; \
	fi
endef

define clean_model_cfg_link
	MODEL=`echo $(NVT_PRJCFG_MODEL_CFG) | awk -F'/' '{print $$(NF-1)}'`; \
	if [ -f $(CONFIG_DIR)/$(NVT_PRJCFG_CFG)/$$MODEL/ModelConfig.mk ]; then \
		rm -rf $(CONFIG_DIR)/$(NVT_PRJCFG_CFG)/$$MODEL/ModelConfig.mk; \
		rm -rf $(CONFIG_DIR)/$(NVT_PRJCFG_CFG)/$$MODEL/MODELEXT; \
	fi; \
	rm -rf $(CONFIG_DIR)/cfg_gen;
endef

define gen_dtb_from_dts
	MODEL=`echo $(NVT_PRJCFG_MODEL_CFG) | awk -F'/' '{print $$(NF-1)}'`; \
	cd $(CONFIG_DIR)/$(NVT_PRJCFG_CFG)/$$MODEL; \
	cpp -nostdinc -D__DTS__ $(C_DEFINE_EXT) -I $(KERNELDIR)/include -I $(KERNELDIR)/arch/arm/boot/dts/include -I $(CONFIG_DIR)/include -I $(LINUX_BUILD_TOP)/base/linux-BSP/linux-kernel/include -undef -x assembler-with-cpp $(NVT_CFG_DTS).dts > $(NVT_CFG_DTS).tmp.dts; \
	if [ "$(DTC_VER)" -le "140" ]; then \
		dtc -O dtb -b 0 -o $(NVT_CFG_DTS).dtb $(NVT_CFG_DTS).tmp.dts; \
	else \
		dtc $(DTC_CFLAGS) -O dtb -b 0 -o $(NVT_CFG_DTS).dtb $(NVT_CFG_DTS).tmp.dts; \
	fi;
endef

define install_dtb
	MODEL=`echo $(NVT_PRJCFG_MODEL_CFG) | awk -F'/' '{print $$(NF-1)}'`; \
	cd $(CONFIG_DIR)/$(NVT_PRJCFG_CFG)/$$MODEL; \
	if [ -f $(NVT_CFG_DTS).dtb ]; then \
		mkdir -p $(OUTPUT_DIR); \
		cp $(NVT_CFG_DTS).dtb $(OUTPUT_DIR)/$(NVT_CFG_DTS).bin; \
	fi;
endef

define gen_modelcfg_from_dtb
	MODEL=`echo $(NVT_PRJCFG_MODEL_CFG) | awk -F'/' '{print $$(NF-1)}'`; \
	cd $(CONFIG_DIR)/$(NVT_PRJCFG_CFG)/$$MODEL; \
	if [ -f $(NVT_CFG_DTS).dtb ]; then \
		$(BUILD_DIR)/nvt-tools/nvt-ld-op --modelcfg-dtb=$(NVT_CFG_DTS).dtb --modelcfg-dst=ModelConfig.mk; \
	else \
		echo "Can't find $(NVT_CFG_DTS).dtb"; \
	fi;
endef

define clean_dtb
	if [ -d $(CONFIG_DIR)/cfg_gen ]; then \
		cd $(CONFIG_DIR)/cfg_gen; \
		rm -rf $(NVT_CFG_DTS).tmp.dts $(NVT_CFG_DTS).dtb; \
	fi;
endef

define show_dtb_res
	dtc -I dtb -O dts $(CONFIG_DIR)/cfg_gen/$(NVT_CFG_DTS).dtb;
endef

define verify_dtb
	$(BUILD_DIR)/nvt-tools/verify_fdt.py -f $(CONFIG_DIR)/cfg_gen/$(NVT_CFG_DTS).dtb;
endef

.PHONY: all

all:
	@$(call gen_dtb_from_dts)
	@$(call gen_modelcfg_from_dtb)
	@$(call gen_model_cfg_link)
	@$(call verify_dtb)

gen_dtb:
	@$(call gen_dtb_from_dts)

gen_modelcfg:
	@$(call gen_modelcfg_from_dtb)
	@$(call gen_model_cfg_link)

dis:
	@$(call show_dtb_res)

install:
	@$(call install_dtb)

clean:
	@$(call clean_dtb)
	@$(call clean_model_cfg_link)
