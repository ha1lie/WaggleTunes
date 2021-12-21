TARGET := iphone:clang:latest:7.0
ARCHS = arm64 arm64e
PREFIX=$(THEOS)/toolchain/Xcode.xctoolchain/usr/bin/
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = WaggleTunes

$(BUNDLE_NAME)_FILES = WTRootListController.m WTAnimatedTitleView.m WTSwitchCell.m WTStepperCell.m
$(BUNDLE_NAME)_FRAMEWORKS = UIKit
$(BUNDLE_NAME)_PRIVATE_FRAMEWORKS = Preferences
$(BUNDLE_NAME)_INSTALL_PATH = /Library/PreferenceBundles
$(BUNDLE_NAME)_EXTRA_FRAMEWORKS += Cephei CepheiPrefs
$(BUNDLE_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
