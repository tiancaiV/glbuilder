
define download_sdk
sdk_target:=$(TOPDIR)/dl/sdk-$(TARGETMODEL-y)-$(TARGETVERSION-y).tar.xz
  $$(sdk_target): $(TOPDIR)/scripts/download.pl .config
	mkdir -p $$(TOPDIR)/dl
	$$< $(TOPDIR)/dl $$(notdir $$@) $$(sdk_hash) $(DOWNLOAD_URL)/sdk/$(TARGETMODEL-y)
endef

define prepare_sdk
sdk_prepare:=$(TOPDIR)/build_dir/sdk-$(TARGETMODEL-y)-$(TARGETVERSION-y)
  $$(sdk_prepare): $$(sdk_target) tmp-prepare
	[ -d $$(sdk_prepare) ] && $(TOPDIR)/scripts/timestamp.pl -n $(TOPDIR)/tmp/sdk/$(TARGETMODEL-y)-$(TARGETVERSION-y)/prepared $(TOPDIR)/dl/$$< || { \
	  mkdir -p $$(sdk_prepare); \
	  tar -xf $$< -C $$@ --strip-components 1 || rm -rf $$@; \
	  echo  "$$(TARGETSDKFEEDS-y)" >$$(sdk_prepare)/feeds.conf.default; \
	  cp $$(TOPDIR)/include/subdir.mk $$(sdk_prepare)/include/subdir.mk; \
	  echo ""  >> $$(sdk_prepare)/feeds.conf.default; \
	  echo "src-link glbuilder $$(TOPDIR)/customer/source"  >> $$(sdk_prepare)/feeds.conf.default; \
	  sed -i 's/^[ \t]*//g' $$(sdk_prepare)/feeds.conf.default; \
	  [ -d $$(sdk_prepare)/dl ] && rm -rf $$(sdk_prepare)/dl || true; \
	  [ -L $$(sdk_prepare)/dl ] && unlink $$(sdk_prepare)/dl || true; \
	  [ -f $$(sdk_prepare)/dl ] || ln -s $$(TOPDIR)/dl $$(sdk_prepare)/dl; \
	  if [ $$(TARGETMODEL-y) = ax1800 -o $$(TARGETMODEL-y) = axt1800 ];then \
	  	sed -i '246,258d' $$(sdk_prepare)/include/package-ipkg.mk; \
		mkdir -p $$(sdk_prepare)/feeds/ipq807x; \
		[ -L $$(sdk_prepare)/feeds/ipq807x/ipq807x ] && unlink $$(sdk_prepare)/feeds/ipq807x/ipq807x || true; \
		ln -s $$(TOPDIR)/feeds/ipq807x/ipq807x/ $$(sdk_prepare)/feeds/ipq807x/ipq807x; \
	  fi; \
	  mkdir -p $(TOPDIR)/tmp/sdk/$(TARGETMODEL-y)-$(TARGETVERSION-y); \
	  touch $(TOPDIR)/tmp/sdk/$(TARGETMODEL-y)-$(TARGETVERSION-y)/prepared; \
	}
endef


define customer_package
$(foreach p,$(sdk_customer_target_packages),
  CUSTOMERPACKAGE-$(p):=$(subst $(TOPDIR)/,,$(CUSTOMERPATH-$(p)))
  $$(CUSTOMERPACKAGE-$(p))/compile: sdk/feeds/update
	$$(SUBMAKE)  -C $$(sdk_prepare) $(JOB_FLAG) package/feeds/glbuilder/$(p)/compile IGNORE_ERRORS=m 2>/dev/null;
	$$(sdk_prepare)/staging_dir/host/bin/find $$(sdk_prepare)/bin -type f -name $(p)*.ipk -exec cp -f {}  $(TOPDIR)/bin/$(TARGETMODEL-y)-$(TARGETVERSION-y)/package/ \;
  $$(CUSTOMERPACKAGE-$(p))/clean: sdk/prepare
	$$(SUBMAKE)  -C $$(sdk_prepare) $(JOB_FLAG)  package/feeds/glbuilder/$(p)/clean IGNORE_ERRORS=m 2>/dev/null;
	-rm -f $(TOPDIR)/bin/$(TARGETMODEL-y)-$(TARGETVERSION-y)/package/$(p)*.ipk
)
endef

sdk_customer_target_packages:= $(sort $(foreach p,$(CUSTOMERPACKAGE-y),$(p) $(CUSTOMERDEP-$(p))))
$(eval $(call download_sdk))
$(eval $(call prepare_sdk))
$(eval $(call customer_package))

sdk/download: $(sdk_target)
sdk/prepare: $(sdk_prepare)
sdk/feeds/update: $(sdk_prepare)
	$(TOPDIR)/scripts/timestamp.pl -n $(TOPDIR)/tmp/sdk/$(TARGETMODEL-y)-$(TARGETVERSION-y)/feeds/stamp-sdk-feeds-update $(sdk_prepare)/feeds $(TOPDIR)/customer/source || \
	$(SUBMAKE) -C $(sdk_prepare) package/symlinks && \
	echo "CONFIG_AUTOREMOVE=n" >> $(sdk_prepare)/.config && \
	echo "CONFIG_AUTOREBUILD=n" >> $(sdk_prepare)/.config && \
	$(SUBMAKE) -C $(sdk_prepare) defconfig && \
	mkdir -p $(TOPDIR)/tmp/sdk/$(TARGETMODEL-y)-$(TARGETVERSION-y)/feeds/ && \
	touch $(TOPDIR)/tmp/sdk/$(TARGETMODEL-y)-$(TARGETVERSION-y)/feeds/stamp-sdk-feeds-update

sdk/compile: sdk/feeds/update tmp/.customer-package.in
	$(foreach p,$(CUSTOMERPACKAGE-y), \
		$(TOPDIR)/scripts/timestamp.pl -n $(sdk_prepare)/tmp/.glbuilder/package/feeds/glbuilder/$(p)/compiled $(CUSTOMERPATH-$(p)) || \
		$(SUBMAKE)  -C $(sdk_prepare) $(JOB_FLAG) package/feeds/glbuilder/$(p)/compile IGNORE_ERRORS=m 2>/dev/null; \
	)

sdk/install: sdk/compile
	mkdir -p $(TOPDIR)/bin/$(TARGETMODEL-y)-$(TARGETVERSION-y)/package
	$(warning  $(sort $(sdk_customer_target_packages)))
	$(foreach p,$(sort $(sdk_customer_target_packages)), \
		$(sdk_prepare)/staging_dir/host/bin/find $(sdk_prepare)/bin -type f -name $(p)*.ipk -exec cp -f {}  $(TOPDIR)/bin/$(TARGETMODEL-y)-$(TARGETVERSION-y)/package/ \;; \
	)

sdk/package/index: sdk/install FORCE
	(cd $(TOPDIR)/bin/$(TARGETMODEL-y)-$(TARGETVERSION-y)/package; $(sdk_prepare)/scripts/ipkg-make-index.sh . > Packages && \
		gzip -9nc Packages > Packages.gz; \
	) >/dev/null 2>/dev/null

sdk/clean:
	rm -rf $(sdk_prepare) || true
	rm -rf $(TOPDIR)/tmp/sdk/$(TARGETMODEL-y)-$(TARGETVERSION-y) || true

.PHONY: sdk/download sdk/clean  sdk/prepare sdk/compile sdk/feeds/update sdk/install sdk/package/index