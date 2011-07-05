include theos/makefiles/common.mk
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 4.0
TWEAK_NAME = TapClockInfo
TapClockInfo_FILES = Tweak.xm
TapClockInfo_FRAMEWORKS=UIKit
include $(THEOS_MAKE_PATH)/tweak.mk
