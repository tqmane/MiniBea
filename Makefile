TARGET := iphone:clang:18.0:14.0
INSTALL_TARGET_PROCESSES = BeReal

# Rootless only supports arm64
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
ARCHS = arm64
else
ARCHS = arm64 arm64e
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MiniBea

$(TWEAK_NAME)_FILES = Tweak/Tweak.x $(shell find Utilities -name '*.m') $(shell find BeFake -name '*.m')
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

ifeq ($(JAILED), 1)
$(TWEAK_NAME)_FILES += fishhook/fishhook.c SideloadFix/SideloadFix.xm
$(TWEAK_NAME)_CFLAGS += -DJAILED=1
endif

include $(THEOS_MAKE_PATH)/tweak.mk
