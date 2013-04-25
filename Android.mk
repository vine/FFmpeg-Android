LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE  := encoding
# These need to be in the right order
FFMPEG_LIBS := $(addprefix ffmpeg/, \
 libavdevice/libavdevice.a \
 libavformat/libavformat.a \
 libavcodec/libavcodec.a \
 libavfilter/libavfilter.a \
 libavresample/libavresample.a \
 libswscale/libswscale.a \
 libswresample/libswresample.a \
 libavutil/libavutil.a \
 libpostproc/libpostproc.a )
# ffmpeg uses its own deprecated functions liberally, so turn off that annoying noise
LOCAL_CFLAGS += -g -Iffmpeg -Irun -Wno-deprecated-declarations 
LOCAL_LDLIBS += -llog -lz $(FFMPEG_LIBS) x264/libx264.a
LOCAL_SRC_FILES := run/co_vine_android_recorder_Processor.c run/ffmpeg.c run/cmdutils.c
include $(BUILD_SHARED_LIBRARY)

# Use to safely invoke ffmpeg multiple times from the same Activity
include $(CLEAR_VARS)

LOCAL_MODULE := ffmpeginvoke

LOCAL_SRC_FILES := ffmpeg_invoke/ffmpeg_invoke.c
LOCAL_LDLIBS    := -ldl

include $(BUILD_SHARED_LIBRARY)