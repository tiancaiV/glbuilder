
define download_sdk
sdk_target:=$(TOPDIR)/dl/sdk-$(TARGETMODEL-y)-$(TARGETVERSION-y).tar.xz
  $$(sdk_target): $(TOPDIR)/scripts/download.pl .config 
	$$< $(TOPDIR)/dl $$(notdir $$@) $$(sdk_hash) $(DOWNLOAD_URL)/sdk/$(TARGETMODEL-y)
endef

define prepare_sdk
sdk_prepare:=$(TOPDIR)/build_dir/sdk-$(TARGETMODEL-y)-$(TARGETVERSION-y)
  $$(sdk_prepare): $$(sdk_target)
	mkdir -p $$(sdk_prepare)
	tar -xf $$< -C $$@ --strip-components 1 || rm -rf $$@
	cp $$(TOPDIR)/board/$$(TARGETMODEL-y)/$$(TARGETVERSION-y)/feeds.conf.default $$(sdk_prepare)/feeds.conf.default
	echo ""  >> $$(sdk_prepare)/feeds.conf.default
	echo "src-link glbuilder $$(TOPDIR)/customer/source"  >> $$(sdk_prepare)/feeds.conf.default
	[ -L $$(sdk_prepare)/dl ] && unlink $$(sdk_prepare)/dl || true
	[ -f $$(sdk_prepare)/dl ] || ln -s $$(TOPDIR)/dl $$(sdk_prepare)/dl
endef


$(eval $(call download_sdk))
$(eval $(call prepare_sdk))


sdk/download: $(sdk_target)
sdk/prepare: $(sdk_prepare)
sdk/feeds/update: $(sdk_prepare)
	$(SUBMAKE) -C $(sdk_prepare) package/symlinks-clean
	$(SUBMAKE) -C $(sdk_prepare) package/symlinks

sdk/compile: sdk/feeds/update tmp/.customer-package.in
	rm $(sdk_prepare)/.config 2>/dev/null || true
	$(SUBMAKE) -C $(sdk_prepare) defconfig
	$(foreach p,$(CUSTOMERPACKAGE-y), \
		$(SUBMAKE)  -C $(sdk_prepare) package/feeds/glbuilder/$(p)/compile IGNORE_ERRORS=m 2>/dev/null; \
	)

sdk/install: sdk/compile
	mkdir -p $(TOPDIR)/bin/$(TARGETMODEL-y)-$(TARGETVERSION-y)/package
	find $(sdk_prepare)/bin -type f -name "*.ipk" -exec cp -f {}  $(TOPDIR)/bin/$(TARGETMODEL-y)-$(TARGETVERSION-y)/package/ \;

sdk/package/index: sdk/install FORCE
	(cd $(TOPDIR)/bin/$(TARGETMODEL-y)-$(TARGETVERSION-y)/package; $(sdk_prepare)/scripts/ipkg-make-index.sh . > Packages && \
		gzip -9nc Packages > Packages.gz; \
	) >/dev/null 2>/dev/null

sdk/clean:
	rm -rf $(sdk_prepare)

.PHONY: sdk/download sdk/clean  sdk/prepare sdk/compile sdk/feeds/update sdk/install sdk/package/index