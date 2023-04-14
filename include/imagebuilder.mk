define download_imagebuilder
imagebuilder_target:=$(TOPDIR)/dl/imagebuilder-$(TARGETMODEL-y)-$(TARGETVERSION-y).tar.xz
  $$(imagebuilder_target): $(TOPDIR)/scripts/download.pl  .config 
	$$< $(TOPDIR)/dl $$(notdir $$@) $$(imagebuilder_hash) $(DOWNLOAD_URL)/imagebuilder/$(TARGETMODEL-y)
endef

define prepare_imagebuilder
imagebuilder_prepare:=$(TOPDIR)/build_dir/imagebuilder-$(TARGETMODEL-y)-$(TARGETVERSION-y)
  $$(imagebuilder_prepare): $$(imagebuilder_target)
	mkdir -p $$(imagebuilder_prepare)
	cp $$(TOPDIR)/scripts/make_gl_metadata.py  $$(imagebuilder_prepare)
	tar -xf $$< -C $$@ --strip-components 1 || rm -rf $$@
	cat $$(TOPDIR)/board/$$(TARGETMODEL-y)/$$(TARGETVERSION-y)/distfeeds.conf > $$(imagebuilder_prepare)/repositories.conf
	echo  "" >> $$(imagebuilder_prepare)/repositories.conf
	echo  "src imagebuilder file:packages" >> $$(imagebuilder_prepare)/repositories.conf
	echo  "src sdksource file://$$(TOPDIR)/bin/$$(TARGETMODEL-y)-$$(TARGETVERSION-y)/package" >> $$(imagebuilder_prepare)/repositories.conf
	echo  "src glbuilder file://$$(TOPDIR)/customer/ipk" >> $$(imagebuilder_prepare)/repositories.conf
endef

define compile_imagebuilder
TARGETPACKAGE-y += $(subst ",,$(CONFIG_CUSTOMER_BUILDIN_PACKAGES))
imagebuilder_compile:=$(TOPDIR)/bin/$(TARGETMODEL-y)-$(TARGETVERSION-y)/target
  $$(imagebuilder_compile): $$(imagebuilder_prepare) FORCE
	mkdir -p $$(imagebuilder_compile)
	mkdir -p $$(TOPDIR)/files/etc
	echo "$(date '+%Y-%m-%d %H:%M:%S')" >$$(TOPDIR)/files/etc/version.date
	echo $$(subst ",,$$(CONFIG_CUSTOMER_VERSION_NUMBER)) >$$(TOPDIR)/files/etc/glversion
	echo $$(subst ",,$$(CONFIG_CUSTOMER_VERSION_NUMBER)) >$$(imagebuilder_prepare)/release
	echo $$(subst ",,$$(CONFIG_CUSTOMER_VERSION_TYPE)) >$$(TOPDIR)/files/etc/version.type
	echo $$(subst ",,$$(CONFIG_CUSTOMER_VERSION_RELEASENOTES)) >$$(imagebuilder_prepare)/gl_release_note
	[ -L $$(imagebuilder_prepare)/files ] && unlink $$(imagebuilder_prepare)/files || true
	[ -f $$(imagebuilder_prepare)/files ] || ln -s $$(TOPDIR)/files $$(imagebuilder_prepare)/files
	$$(SUBMAKE) -C $$(imagebuilder_prepare) image PROFILE=$$(MODEL_PROFILE) PACKAGES="$$(TARGETPACKAGE-y)" BIN_DIR=$$@ FILES=$$(TOPDIR)/files
endef

$(eval $(call download_imagebuilder))
$(eval $(call prepare_imagebuilder))
$(eval $(call compile_imagebuilder))

customer/package/ipk/index: $(imagebuilder_prepare) FORCE
	(cd $(TOPDIR)/customer/ipk; $(imagebuilder_prepare)/scripts/ipkg-make-index.sh . > Packages && \
		gzip -9nc Packages > Packages.gz; \
	) >/dev/null 2>/dev/null

imagebuilder/download: $(imagebuilder_target)
imagebuilder/prepare: $(imagebuilder_prepare)

ifneq ($(CUSTOMERPACKAGE-y),)
imagebuilder/compile: customer/package/ipk/index sdk/package/index  $(imagebuilder_compile)
else
imagebuilder/compile: customer/package/ipk/index   $(imagebuilder_compile)
endif

imagebuilder/clean:
	rm -rf $(imagebuilder_prepare)

.PHONY: imagebuilder/download  imagebuilder/prepare imagebuilder/compile customer/package/ipk/index imagebuilder/clean