#include <android/log.h>
#include "logjam.h"
#include "co_vine_android_recorder_Processor.h"

#include <stdlib.h>
#include <stdbool.h>

bool initted = false;

int main(int argc, char **argv);

static JavaVM *sVm;

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *jvm, void *reserved)
{
	LOGI("Loading native library compiled at " __TIME__ " " __DATE__);
	sVm = jvm;
	return JNI_VERSION_1_2;
}

// the fuck is this exit shit doing
#define exit exit_function_not_allowed
#define LOG_ERROR(message) __android_log_write(ANDROID_LOG_ERROR, "VideoKit", message)
#define LOG_INFO(message) __android_log_write(ANDROID_LOG_INFO, "VideoKit", message)
#define EXCEPTION_CODE 256

int throwException(JNIEnv *env, const char* message)
{
  jclass newExcCls;
  (*env)->ExceptionDescribe(env);
  (*env)->ExceptionClear(env);
  newExcCls = (*env)->FindClass(env, "java/lang/IllegalArgumentException");
  (*env)->ThrowNew(env, newExcCls, message);
  (*env)->DeleteLocalRef(env, newExcCls);
  return EXCEPTION_CODE;
}


JNIEXPORT jint JNICALL Java_co_vine_android_recorder_Processor_run(JNIEnv *env, jobject obj, jobjectArray args)
{
	LOGD("run()");
	int i = 0;
	int argc = 0;
	char **argv = NULL;

	if (args != NULL) {
		argc = (*env)->GetArrayLength(env, args);
		argv = (char **) malloc(sizeof(char *) * argc);

		for(i=0;i<argc;i++){
			jstring str = (jstring)(*env)->GetObjectArrayElement(env, args, i);
			argv[i] = (char *)(*env)->GetStringUTFChars(env, str, NULL);   
		}
	}

	LOGD("ffmpeg main()");
	return main(argc, argv);
}

#if 0
JNIEXPORT void JNICALL Java_co_vine_android_recorder_Processor_initialise(JNIEnv *env, jobject self)
{
  if (!initted) 
  {
    LOG_INFO("Initialize");
    av_register_all();
    initted = true;
  }
  else
  {
    LOG_INFO("Already initialized, ignoring init()");    
  }
}

#endif
