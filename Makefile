TOPDIR:=${CURDIR}
SUBMAKE:=make
MKHASH:=$(TOPDIR)/host/bin/mkhash
export MKHASH
export TOPDIR
export PATH:=$(TOPDIR)/host/bin:$(PATH)
AWS_URL:=https://fw.gl-inet.com/releases
ALIYUN_URL:=https://fw.gl-inet.cn/releases

MAKE_PID := $(shell echo $$PPID)
JOB_FLAG := $(filter -j%, $(subst -j ,-j,$(shell ps T | grep "^\s*$(MAKE_PID).*$(MAKE)")))
ifndef MAKE_FLAG
  MAKE_FLAG:=
endif
ifeq ("$(origin V)", "command line")
  MAKE_FLAG:=V=$(V)
endif

ifneq ($(GLBUILD),1)
  override GLBUILD=1
  export GLBUILD
  include $(TOPDIR)/include/tmpprepare.mk
else
  $(TOPDIR)/.config: .config
  $(TOPDIR)/tmp/.configdeps: tmp/.customer-package.in
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

world: .config  imagebuilder/compile FORCE
	@echo "done"
endif

FORCE: ;
.PHONY: FORCE world