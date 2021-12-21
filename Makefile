TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64 arm64e
PACKAGE_VERSION = 1.3.1

PREFIX=$(THEOS)/toolchain/Xcode.xctoolchain/usr/bin/

include $(THEOS)/makefiles/common.mk
TWEAK_NAME = NotchTunes

NotchTunes_FILES = Tweak.xm TunesController.m CCColorCube.m CCLocalMaximum.m
NotchTunes_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_FRAMEWORKS = AudioToolbox
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = MediaRemote
$(TWEAK_NAME)_EXTRA_FRAMEWORKS += Cephei

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += waggletunes
include $(THEOS_MAKE_PATH)/aggregate.mk
