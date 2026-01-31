#---------------------------------------------------------------------------------
# path to tools - this can be deleted if you set the path in windows
#---------------------------------------------------------------------------------
#export DEVKITPRO=/opt/devkitpro
#export DEVKITARM=/opt/devkitpro/devkitARM
#
#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------
ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM)
endif

include $(DEVKITARM)/ds_rules

export TARGET		:=	DracoDS
export TOPDIR		:=	$(CURDIR)
export VERSION		:=  1.4c
export BUILD_TYPE	:=	dev

# Git info for dev builds
GIT_HASH := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_DIRTY := $(shell git diff --quiet 2>/dev/null || echo "-dirty")

# Build type
BUILD_TYPE ?= dev
ifeq ($(BUILD_TYPE),dev)
    VERSION_SUFFIX := -$(GIT_HASH)$(GIT_DIRTY)
    ICON := -b $(CURDIR)/logo.bmp "DracoDS $(VERSION)$(VERSION_SUFFIX);wavemotion-dave;https://github.com/wavemotion-dave/DracoDS"
else
    VERSION_SUFFIX :=
    ICON := -b $(CURDIR)/logo.bmp "DracoDS $(VERSION);wavemotion-dave;https://github.com/wavemotion-dave/DracoDS"
endif

# Target filename with version
TARGET_VERSIONED := $(TARGET)-$(VERSION)$(VERSION_SUFFIX)

.PHONY: $(TARGET).nds $(TARGET_VERSIONED).nds $(TARGET).arm7 $(TARGET).arm9

.PHONY: arm7/$(TARGET).elf arm9/$(TARGET).elf dev release all clean

# Auto-generate version.h
arm9/source/version.h: FORCE
	@echo "Generating version.h..."
	@echo "#ifndef VERSION_H" > $@
	@echo "#define VERSION_H" >> $@
	@echo "" >> $@
	@echo "#define EMULATOR_NAME \"DracoDS\"" >> $@
	@echo "#define VERSION_MAJOR 1" >> $@
	@echo "#define VERSION_MINOR 4" >> $@
	@echo "#define VERSION_PATCH c" >> $@
	@echo '#define VERSION_STRING "v$(VERSION)"' >> $@
ifneq ($(BUILD_TYPE),dev)
	@echo '#define VERSION_FULL "DracoDS v$(VERSION)"' >> $@
else
	@echo '#define VERSION_FULL "DracoDS v$(VERSION)$(VERSION_SUFFIX)"' >> $@
	@echo '#define GIT_HASH "$(GIT_HASH)"' >> $@
	@echo '#define GIT_DIRTY "$(GIT_DIRTY)"' >> $@
endif
	@echo '#define BUILD_DATE __DATE__' >> $@
	@echo '#define BUILD_TIME __TIME__' >> $@
	@echo "" >> $@
	@echo "#endif // VERSION_H" >> $@

FORCE:

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
ifeq ($(BUILD_TYPE),dev)
    all: $(TARGET_VERSIONED).nds
else
    all: $(TARGET).nds
endif


# Dev build with git info
dev: export BUILD_TYPE := dev
dev: $(TARGET_VERSIONED).nds

$(TARGET_VERSIONED).nds: arm9/source/version.h arm7/$(TARGET).elf arm9/$(TARGET).elf
	@echo "Building DracoDS $(VERSION)$(VERSION_SUFFIX)..."
	ndstool -c $(TARGET_VERSIONED).nds -7 arm7/$(TARGET).elf -9 arm9/$(TARGET).elf -b $(CURDIR)/logo.bmp "DracoDS $(VERSION)$(VERSION_SUFFIX);wavemotion-dave;https://github.com/wavemotion-dave/DracoDS"

# Release build (default)
release: export BUILD_TYPE := release
release: $(TARGET).nds

$(TARGET).nds: arm9/source/version.h arm7/$(TARGET).elf arm9/$(TARGET).elf
	@echo "Building DracoDS $(VERSION)..."
	ndstool -c $(TARGET).nds -7 arm7/$(TARGET).elf -9 arm9/$(TARGET).elf -b $(CURDIR)/logo.bmp "DracoDS $(VERSION);wavemotion-dave;https://github.com/wavemotion-dave/DracoDS"

# Build both ARM7 and ARM9 (used by both release and dev)
arm7/$(TARGET).elf arm9/$(TARGET).elf: arm9/source/version.h
	$(MAKE) -C arm7 TARGET=$(TARGET)
	$(MAKE) -C arm9 TARGET=$(TARGET)
  
#---------------------------------------------------------------------------------
clean:
	$(MAKE) -C arm9 clean
	$(MAKE) -C arm7 clean
	rm -f $(TARGET).nds $(TARGET).arm7 $(TARGET).arm9
	rm -f $(TARGET)-*.nds
	rm -f arm9/source/version.h
