include theos/makefiles/common.mk

TWEAK_NAME = TapClockInfo
TapClockInfo_FILES = Tweak.xm
TapClockInfo_FRAMEWORKS=UIKit
include $(THEOS_MAKE_PATH)/tweak.mk
