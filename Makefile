TARGET := iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES = BeReal

# Support for rootless and rootful
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
# Rootless only supports arm64
ARCHS = arm64
else
ARCHS = arm64 arm64e
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MiniBea

$(TWEAK_NAME)_FILES = Tweak/Tweak.x $(shell find Utilities -name '*.m') $(shell find BeFake -name '*.m')
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -fno-modules -Wno-module-import-in-extern-c
$(TWEAK_NAME)_CCFLAGS = -fno-modules

ifeq ($(JAILED), 1)
$(TWEAK_NAME)_FILES += fishhook/fishhook.c SideloadFix/SideloadFix.xm
$(TWEAK_NAME)_CFLAGS += -DJAILED=1
endif

include $(THEOS_MAKE_PATH)/tweak.mk
