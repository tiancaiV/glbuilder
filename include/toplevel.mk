$(TOPDIR)/host/bin/mkhash: $(TOPDIR)/scripts/mkhash.c
	mkdir -p $(dir $@)
	$(CC) -O2 -o $@ $<

tools-prepare: $(TOPDIR)/host/bin/mkhash

tmp-prepare: FORCE
	mkdir -p $(TOPDIR)/tmp
	$(TOPDIR)/scripts/scanboarddir.sh $(TOPDIR)/board

tmp/.customer-package.in: tmp-prepare FORCE
	mkdir -p $(TOPDIR)/tmp/customer.tmp/info
	rm -rf $(TOPDIR)/tmp/customer.tmp/info/.* 2>/dev/null || true
	$(SUBMAKE) -s -f $(TOPDIR)/include/scan.mk IS_TTY=1 SCAN_TARGET="packageinfo" SCAN_DIR=$(TOPDIR)/customer/source SCAN_NAME="package" \
	  SCAN_DEPTH=5 SCAN_EXTRA="" TMP_DIR=$(TOPDIR)/tmp/customer.tmp INCLUDE_DIR=$(TOPDIR)/include
	$(TOPDIR)/scripts/package-metadata.pl config $(TOPDIR)/tmp/customer.tmp/.packageinfo > $@
	$(TOPDIR)/scripts/package-metadata.pl mk $(TOPDIR)/tmp/customer.tmp/.packageinfo 2>/dev/null >> $(TOPDIR)/tmp/.configdeps

scripts/config/%onf: CFLAGS+= -O2
scripts/config/%onf:
	$(SUBMAKE) -C $(TOPDIR)/scripts/config $(notdir $@)

menuconfig: scripts/config/mconf tmp-prepare tmp/.customer-package.in
	$< ./Config.in

.config:scripts/config/mconf tmp-prepare tmp/.customer-package.in tools-prepare FORCE
	@+if [ \! -e .config ] ; then \
		 $(TOPDIR)/scripts/config/mconf ./Config.in; \
	fi