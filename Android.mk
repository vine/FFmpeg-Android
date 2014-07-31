LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_ARCH_ABI),x86)
  LIB_VERSION=x86
else
  LIB_VERSION=neon
endif

include $(CLEAR_VARS)

LOCAL_MODULE  := encoding

# These need to be in the right order
FFMPEG_LIBS := $(addprefix ./build/ffmpeg/$(LIB_VERSION)/lib/, \
 libavdevice.a \
 libavformat.a \
 libavcodec.a \
 libavfilter.a \
 libavresample.a \
 libswscale.a \
 libswresample.a \
 libavutil.a \
 libpostproc.a )


# ffmpeg uses its own deprecated functions liberally, so turn off that annoying noise
LOCAL_CFLAGS += -g -Iffmpeg -Irun -Wno-deprecated-declarations 
LOCAL_LDLIBS += -llog -lz $(FFMPEG_LIBS) ./build/x264/$(LIB_VERSION)/lib/libx264.a
LOCAL_SRC_FILES := run/co_vine_android_recorder_Processor.c run/ffmpeg.c run/cmdutils.c
include $(BUILD_SHARED_LIBRARY)

# Use to safely invoke ffmpeg multiple times from the same Activity
include $(CLEAR_VARS)

LOCAL_MODULE := ffmpeginvoke

LOCAL_SRC_FILES := ffmpeg_invoke/ffmpeg_invoke.c
LOCAL_LDLIBS    := -ldl

include $(BUILD_SHARED_LIBRARY)
