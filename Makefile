TOPDIR:=${CURDIR}
SUBMAKE:=make

export TOPDIR
export PATH:=$(TOPDIR)/host/bin:$(PATH)

AWS_URL:=https://fw.gl-inet.com/releases
ALIYUN_URL:=https://fw.gl-inet.cn/releases

world:

$(TOPDIR)/host/bin/mkhash: $(TOPDIR)/scripts/mkhash.c
	mkdir -p $(dir $@)
	$(CC) -O2 -o $@ $<

tools-prepare: $(TOPDIR)/host/bin/mkhash

tmp-prepare:
	$(TOPDIR)/scripts/scanboarddir.sh $(TOPDIR)/board

tmp/.customer-package.in: tmp-prepare FORCE
	mkdir -p $(TOPDIR)/tmp/customer.tmp/info
	rm -rf $(TOPDIR)/tmp/customer.tmp/info/.* 2>/dev/null || true
	$(SUBMAKE) -s -f $(TOPDIR)/include/scan.mk IS_TTY=1 SCAN_TARGET="packageinfo" SCAN_DIR=$(TOPDIR)/customer/source SCAN_NAME="package" \
	  SCAN_DEPTH=5 SCAN_EXTRA="" TMP_DIR=$(TOPDIR)/tmp/customer.tmp INCLUDE_DIR=$(TOPDIR)/include
	$(TOPDIR)/scripts/package-metadata.pl config $(TOPDIR)/tmp/customer.tmp/.packageinfo > $@
	$(TOPDIR)/scripts/package-metadata.pl mk $(TOPDIR)/tmp/customer.tmp/.packageinfo 2>/dev/null >> $(TOPDIR)/tmp/.configdeps

cripts/config/%onf: CFLAGS+= -O2
scripts/config/%onf:
	$(SUBMAKE) -C $(TOPDIR)/scripts/config $(notdir $@)

menuconfig: scripts/config/mconf tmp-prepare tmp/.customer-package.in
	$< ./Config.in

.config:tmp-prepare FORCE
	@+if [ \! -e .config ] ; then \
		$(SUBMAKE) menuconfig; \
	fi

-include $(TOPDIR)/.config
-include $(TOPDIR)/tmp/.configdeps

ifeq ($(CONFIG_DOWNLOAD_FROM_AWS),y)
DOWNLOAD_URL:=$(AWS_URL)
else
DOWNLOAD_URL:=$(ALIYUN_URL)
endif

-include $(TOPDIR)/board/$(TARGETMODEL-y)/$(TARGETVERSION-y)/version_info.mk
include $(TOPDIR)/include/sdk.mk
include $(TOPDIR)/include/imagebuilder.mk




world: .config tools-prepare imagebuilder/compile
	@echo "done"

clean:
	rm -rf $(TOPDIR)/build_dir 2>/dev/null || true
	rm -rf $(TOPDIR)/tmp 2>/dev/null || true
	rm -rf $(TOPDIR)/host 2>/dev/null || true
	rm $(TOPDIR)/.config* 2>/dev/null || true

distclean: clean
	$(SUBMAKE) -C $(TOPDIR)/scripts/config clean
	rm -rf $(TOPDIR)/dl 2>/dev/null || true
	rm -rf $(TOPDIR)/files/* 2>/dev/null || true
	rm -rf $(TOPDIR)/bin 2>/dev/null || true
	rm -rf $(TOPDIR)/customer/ipk/* 2>/dev/null || true
	rm -rf $(TOPDIR)/customer/source/* 2>/dev/null || true
	

FORCE: ;
.PHONY: FORCE world menuconfig clean distclean
