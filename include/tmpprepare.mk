world:

SUBMAKE:=make

$(TOPDIR)/host/bin/mkhash: $(TOPDIR)/scripts/mkhash.c
	mkdir -p $(dir $@)
	$(CC) -O2 -o $@ $<


tmp-prepare: FORCE
	mkdir -p $(TOPDIR)/tmp
	$(TOPDIR)/scripts/scanboarddir.sh $(TOPDIR)/board

$(TOPDIR)/tmp/.customer-package.in: tmp-prepare FORCE
	mkdir -p $(TOPDIR)/tmp/customer.tmp/info
	rm -rf $(TOPDIR)/tmp/customer.tmp/info/.* 2>/dev/null || true
	$(SUBMAKE) -s -f $(TOPDIR)/include/scan.mk IS_TTY=1 SCAN_TARGET="packageinfo" SCAN_DIR=$(TOPDIR)/customer/source SCAN_NAME="package" \
	  SCAN_DEPTH=5 SCAN_EXTRA="" TMP_DIR=$(TOPDIR)/tmp/customer.tmp INCLUDE_DIR=$(TOPDIR)/include
	$(TOPDIR)/scripts/package-metadata.pl config $(TOPDIR)/tmp/customer.tmp/.packageinfo > $@
	$(TOPDIR)/scripts/package-metadata.pl mk $(TOPDIR)/tmp/customer.tmp/.packageinfo 2>/dev/null >> $(TOPDIR)/tmp/.configdeps

scripts/config/%onf: CFLAGS+= -O2
scripts/config/%onf:
	$(SUBMAKE) -C $(TOPDIR)/scripts/config $(notdir $@)

menuconfig: scripts/config/mconf tmp-prepare $(TOPDIR)/tmp/.customer-package.in
	$< ./Config.in

defconfig: scripts/config/conf tmp-prepare $(TOPDIR)/tmp/.customer-package.in FORCE
	touch .config
	$< --defconfig=.config Config.in

.config:scripts/config/mconf tmp-prepare $(TOPDIR)/tmp/.customer-package.in $(TOPDIR)/host/bin/mkhash FORCE
	@+if [ \! -e .config ] ; then \
		 $(TOPDIR)/scripts/config/mconf ./Config.in; \
	fi

world:
	$(SUBMAKE) -f $(TOPDIR)/include/tmpprepare.mk .config
	$(SUBMAKE) $(JOB_FLAG) $(MAKE_FLAG) $@

clean:
	rm -rf $(TOPDIR)/build_dir 2>/dev/null || true
	rm -rf $(TOPDIR)/tmp 2>/dev/null || true
	rm -rf $(TOPDIR)/host 2>/dev/null || true
	rm $(TOPDIR)/.config* 2>/dev/null || true

distclean: clean
	$(SUBMAKE) -f $(TOPDIR)/include/tmpprepare.mk clean
	rm -rf $(TOPDIR)/files/* 2>/dev/null || true
	rm -rf $(TOPDIR)/bin 2>/dev/null || true

%::
	$(SUBMAKE) -f $(TOPDIR)/include/tmpprepare.mk .config
	$(SUBMAKE) $(JOB_FLAG) $(MAKE_FLAG) $@

FORCE:;
.PHONY:menuconfig clean distclean tmp/.customer-package.in

