define download_imagebuilder
imagebuilder_target:=$(TOPDIR)/dl/imagebuilder-$(TARGETMODEL-y)-$(TARGETVERSION-y).tar.xz
  $$(imagebuilder_target): $(TOPDIR)/scripts/download.pl .config 
	mkdir -p $$(TOPDIR)/dl
	$$< $(TOPDIR)/dl $$(notdir $$@) $$(imagebuilder_hash) $(DOWNLOAD_URL)/imagebuilder/$(TARGETMODEL-y)
endef

define prepare_imagebuilder
imagebuilder_prepare:=$(TOPDIR)/build_dir/imagebuilder-$(TARGETMODEL-y)-$(TARGETVERSION-y)
  $$(imagebuilder_prepare): $$(imagebuilder_target)
	[ -d $$(imagebuilder_prepare) ] && $(TOPDIR)/scripts/timestamp.pl -n $(TOPDIR)/tmp/imagebuilder/$(TARGETMODEL-y)-$(TARGETVERSION-y)/prepared $(TOPDIR)/dl/$$< || { \
	  mkdir -p $$(imagebuilder_prepare); \
	  cp $$(TOPDIR)/scripts/make_gl_metadata.py  $$(imagebuilder_prepare); \
	  tar -xf $$< -C $$@ --strip-components 1 || rm -rf $$@; \
	  rm -f $$(imagebuilder_prepare)/repositories.conf; \
	  [ "$(CONFIG_NOT_USE_REMOTE_REPO)" = "y" ] || \
	  	cat $$(TOPDIR)/board/$$(TARGETMODEL-y)/$$(TARGETVERSION-y)/distfeeds.conf|grep -v kmod > $$(imagebuilder_prepare)/repositories.conf; \
	  echo  "" >> $$(imagebuilder_prepare)/repositories.conf; \
	  echo  "src imagebuilder file:packages" >> $$(imagebuilder_prepare)/repositories.conf; \
	  echo  "src sdksource file://$$(TOPDIR)/bin/$$(TARGETMODEL-y)-$$(TARGETVERSION-y)/package" >> $$(imagebuilder_prepare)/repositories.conf; \
	  echo  "src glbuilder file://$$(TOPDIR)/customer/ipk" >> $$(imagebuilder_prepare)/repositories.conf; \
	  if [ $$(TARGETMODEL-y) = ax1800 -o $$(TARGETMODEL-y) = axt1800 ];then \
		mkdir -p $$(imagebuilder_prepare)/feeds/ipq807x; \
		[ -L $$(imagebuilder_prepare)/feeds/ipq807x/ipq807x ] && unlink $$(imagebuilder_prepare)/feeds/ipq807x/ipq807x || true; \
		ln -s $$(TOPDIR)/feeds/ipq807x/ipq807x/ $$(imagebuilder_prepare)/feeds/ipq807x/ipq807x; \
	  fi; \
	  mkdir -p $(TOPDIR)/tmp/imagebuilder/$(TARGETMODEL-y)-$(TARGETVERSION-y); \
	  touch $(TOPDIR)/tmp/imagebuilder/$(TARGETMODEL-y)-$(TARGETVERSION-y)/prepared; \
	}
endef

define compile_imagebuilder
TARGETPACKAGE-y += $(gl_collision_package) $(subst ",,$(CONFIG_CUSTOMER_BUILDIN_PACKAGES)) $(CUSTOMERPACKAGE-y)
imagebuilder_compile:=$(TOPDIR)/bin/$(TARGETMODEL-y)-$(TARGETVERSION-y)/target
ifneq ($$(CUSTOMERPACKAGE-y),)
  $$(imagebuilder_compile): $$(imagebuilder_prepare) sdk/package/index FORCE
else
  $$(imagebuilder_compile): $$(imagebuilder_prepare) FORCE
endif
	mkdir -p $$(imagebuilder_compile)
	-rm -rf $$(imagebuilder_prepare)/files 2>/dev/null 
	mkdir -p $$(imagebuilder_prepare)/files/etc
	-[ -n $(CONFIG_SIGNATURE_KEY_PATH) ] && \
		[ -d $(CONFIG_SIGNATURE_KEY_PATH) ] && [ -f $(CONFIG_SIGNATURE_KEY_PATH)/key-build ] && [ -f $(CONFIG_SIGNATURE_KEY_PATH)/key-build.pub ] && \
	  		cp $(CONFIG_SIGNATURE_KEY_PATH)/key-build*  $$(imagebuilder_prepare)/ && \
			cp $(CONFIG_SIGNATURE_KEY_PATH)/key-build.pub $$(imagebuilder_prepare)/files/etc;
	echo "$(date '+%Y-%m-%d %H:%M:%S')" >$$(imagebuilder_prepare)/files/etc/version.date
ifneq ($$(CONFIG_CUSTOMER_VERSION_NUMBER),"")
	echo "$$(subst ",,$$(CONFIG_CUSTOMER_VERSION_NUMBER))" >$$(imagebuilder_prepare)/files/etc/glversion
	echo "$$(subst ",,$$(CONFIG_CUSTOMER_VERSION_NUMBER))" >$$(imagebuilder_prepare)/release
else
	echo "$$(TARGETVERSION-y)" >$$(imagebuilder_prepare)/files/etc/glversion
	echo "$$(TARGETVERSION-y)" >$$(imagebuilder_prepare)/release
endif
	echo "$$(subst ",,$$(CONFIG_CUSTOMER_VERSION_TYPE))" >$$(imagebuilder_prepare)/files/etc/version.type
	echo "$$(subst ",,$$(CONFIG_CUSTOMER_VERSION_RELEASENOTES))" >$$(imagebuilder_prepare)/gl_release_note
	mkdir -p $$(imagebuilder_prepare)/files/etc/opkg
	-cp $$(TOPDIR)/board/$$(TARGETMODEL-y)/$$(TARGETVERSION-y)/distfeeds.conf  $$(imagebuilder_prepare)/files/etc/opkg/
	-cp -r $$(TOPDIR)/files/* $$(imagebuilder_prepare)/files
	$$(SUBMAKE) -C $$(imagebuilder_prepare) image PROFILE=$$(MODEL_PROFILE) PACKAGES="$$(TARGETPACKAGE-y)" BIN_DIR=$$@ FILES=$$(imagebuilder_prepare)/files
endef

$(eval $(call download_imagebuilder))
$(eval $(call prepare_imagebuilder))
$(eval $(call compile_imagebuilder))

customer/ipk/index: $(imagebuilder_prepare) FORCE
	-(cd $(TOPDIR)/customer/ipk; $(imagebuilder_prepare)/scripts/ipkg-make-index.sh . > Packages && \
		gzip -9nc Packages > Packages.gz; \
	) >/dev/null 2>/dev/null

imagebuilder/download: $(imagebuilder_target)
imagebuilder/prepare: $(imagebuilder_prepare)

imagebuilder/compile: customer/ipk/index   $(imagebuilder_prepare)  $(imagebuilder_compile)

imagebuilder/clean:
	rm -rf $(imagebuilder_prepare) || true
	rm -rf $(TOPDIR)/tmp/imagebuilder/$(TARGETMODEL-y)-$(TARGETVERSION-y) || true

.PHONY: imagebuilder/download  imagebuilder/prepare imagebuilder/compile customer/ipk/index imagebuilder/clean
