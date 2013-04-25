#ifndef FFMPEG_INVOKE_H_INCLUDED
#define FFMPEG_INVOKE_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

#include <jni.h>

// Use to safely invoke ffmpeg multiple times from the same Activity
jint Java_co_vine_android_recorder_FFmpegInvoke_run(JNIEnv*, jobject, jstring, jobjectArray);

#ifdef __cplusplus
}
#endif

#endif // FFMPEG_INVOKE_H_INCLUDED