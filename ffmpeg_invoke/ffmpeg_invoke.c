#include <stdlib.h>
#include <dlfcn.h>
#include "ffmpeg_invoke.h"

static JavaVM *sVm;

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *jvm, void *reserved)
{
        sVm = jvm;
        return JNI_VERSION_1_2;
}


jint Java_co_vine_android_recorder_FFmpegInvoke_run(JNIEnv* env, jobject obj, 
jstring libffmpeg_path, jobjectArray ffmpeg_args)
{
	const char* path;
	void* handle;
	jint (*Java_co_vine_android_recorder_Processor_run)(JNIEnv*, jobject, jobjectArray);

	path = (*env)->GetStringUTFChars(env, libffmpeg_path, 0);
	handle = dlopen(path, RTLD_LAZY);
	(*env)->ReleaseStringUTFChars(env, libffmpeg_path, path);

	Java_co_vine_android_recorder_Processor_run = dlsym(handle, "Java_co_vine_android_recorder_Processor_run");
	jint ret= (*Java_co_vine_android_recorder_Processor_run)(env, obj, ffmpeg_args);

	dlclose(handle);
	return ret;
}