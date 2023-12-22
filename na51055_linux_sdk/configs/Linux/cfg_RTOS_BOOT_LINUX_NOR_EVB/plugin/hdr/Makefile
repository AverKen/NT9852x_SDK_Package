MODULE_NAME = plugin_$(shell basename $(PWD))
# dtb includes
DTB_INCLUDE = \
	-I$(KERNELDIR)/include \
	-I$(KERNELDIR)/arch/arm/boot/dts/include \
	-I$(CONFIG_DIR)/include \
	-I$(LINUX_BUILD_TOP)/base/linux-BSP/linux-kernel/include


.PHONY: all clean

###############################################################################
# Linux Makefile                                                              #
###############################################################################
ifeq ($(NVT_PRJCFG_CFG),Linux)
DTBNAME = $(MODULE_NAME).dtb
#--------- END OF ENVIRONMENT SETTING -------------
DTS_SRC = plugin.dts

all: $(DTBNAME)

$(DTBNAME): $(wildcard *.dtsi) $(wildcard *.dts)

$(DTBNAME): $(DTS_SRC)
	@echo generate $@
	@cpp -nostdinc $(DTB_INCLUDE) -undef -x assembler-with-cpp $< > $<.tmp \
	&& dtc -O dtb -b 0 -o $@ $<.tmp \
	&& rm $<.tmp

clean:
	@rm -f $(DTBNAME)

install:
	@cp -arf -t $(ROOTFS_DIR)/rootfs/etc $(DTBNAME)

###############################################################################
# rtos Makefile                                                               #
###############################################################################
else ifeq ($(NVT_PRJCFG_CFG),rtos)

DTS_SRC = plugin.dts
DTB = $(DTS_SRC:.dts=.dtb)

all: $(DTB)

$(DTB): $(wildcard *.dtsi) $(wildcard *.dts)

%.dtb: %.dts
	@echo Compiling $<
	@cpp -nostdinc $(DTB_INCLUDE) -undef -x assembler-with-cpp $< > $<.tmp \
	&& dtc -O dtb -b 0 -o $@ $<.tmp \
	&& rm $<.tmp

clean:
	@rm -f $(DTB)

install:

endif
