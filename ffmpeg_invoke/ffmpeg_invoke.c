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


int* rgbData;
int rgbDataSize = 0;

void Java_co_vine_android_recorder_FFmpegInvoke_YUVtoRBG(JNIEnv * env, jobject obj, jintArray rgb, jbyteArray yuv420sp, jint width, jint height)
{
    int             sz;
    int             i;
    int             j;
    int             Y;
    int             Cr = 0;
    int             Cb = 0;
    int             pixPtr = 0;
    int             jDiv2 = 0;
    int             R = 0;
    int             G = 0;
    int             B = 0;
    int             cOff;
	int w = width;
	int h = height;
    sz = w * h;

    jboolean isCopy;
    jbyte* yuv = (*env)->GetByteArrayElements(env, yuv420sp, &isCopy);
	if(rgbDataSize < sz) {
		int tmp[sz];
		rgbData = &tmp[0];
		rgbDataSize = sz;

	}

	for(j = 0; j < h; j++) {
             pixPtr = j * w;
             jDiv2 = j >> 1;
             for(i = 0; i < w; i++) {
                     Y = yuv[pixPtr];
					 if(Y < 0) Y += 255;
                     if((i & 0x1) != 1) {
                             cOff = sz + jDiv2 * w + (i >> 1) * 2;
                             Cb = yuv[cOff];
                             if(Cb < 0) Cb += 127; else Cb -= 128;
                             Cr = yuv[cOff + 1];
                             if(Cr < 0) Cr += 127; else Cr -= 128;
                     }
                     R = Y + Cr + (Cr >> 2) + (Cr >> 3) + (Cr >> 5);//1.406*~1.403
                     if(R < 0) R = 0; else if(R > 255) R = 255;
                     G = Y - (Cb >> 2) + (Cb >> 4) + (Cb >> 5) - (Cr >> 1) + (Cr >> 3) + (Cr >> 4) + (Cr >> 5);//
                     if(G < 0) G = 0; else if(G > 255) G = 255;
                     B = Y + Cb + (Cb >> 1) + (Cb >> 2) + (Cb >> 6);//1.765~1.770
                     if(B < 0) B = 0; else if(B > 255) B = 255;
                     rgbData[pixPtr++] = 0xff000000 + (B << 16) + (G << 8) + R;
             }
    }
	(*env)->SetIntArrayRegion(env, rgb, 0, sz, ( jint * ) &rgbData[0] );

	(*env)->ReleaseByteArrayElements(env, yuv420sp, yuv, JNI_ABORT);
}