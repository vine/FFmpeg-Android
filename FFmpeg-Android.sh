#!/bin/bash
DEST=`pwd`/build/ffmpeg && rm -rf $DEST
SOURCE=`pwd`/ffmpeg
X264_DEST=`pwd`/build/x264 && rm -rf $X264_DEST
X264_SOURCE=`pwd`/x264

TOOLCHAIN_ARM=/tmp/vplayer-arm
TOOLCHAIN_X86=/tmp/vplayer-x86
SYSROOT_ARM=$TOOLCHAIN_ARM/sysroot/
SYSROOT_X86=$TOOLCHAIN_X86/sysroot/
EXTRA_ARM_CFLAGS="-mthumb -fstrict-aliasing -Werror=strict-aliasing -D__ARM_ARCH_5__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5TE__ -Wl,--fix-cortex-a8"

export PATH=$TOOLCHAIN_ARM/bin:$TOOLCHAIN_X86/bin:$PATH

CFLAGS="-O3 -Wall -pipe -fpic -fasm \
  -finline-limit=300 -ffast-math \
  -fmodulo-sched -fmodulo-sched-allow-regmoves \
  -Wno-psabi -Wa,--noexecstack \
  -DANDROID -DNDEBUG"

X264_FLAGS="--enable-pic --enable-static"

FFMPEG_FLAGS="--target-os=linux \
  --enable-cross-compile \
  --enable-shared \
  --disable-symver \
  --disable-doc \
  --disable-ffplay \
  --disable-ffmpeg \
  --disable-ffprobe \
  --disable-ffserver \
  --enable-protocols  \
  --enable-fft \
  --enable-rdft \
  --enable-pthreads \
  --enable-parsers \
  --enable-demuxers \
  --enable-decoders \
  --enable-bsfs \
  --enable-network \
  --enable-swscale  \
  --enable-swresample  \
  --enable-avresample \
  --enable-hwaccels \
  --enable-decoder=rawvideo \
  --enable-encoder=aac,libx264 \
  --enable-libx264 \
  --enable-asm \
  --enable-gpl \
  --enable-version3"

if [ -d $TOOLCHAIN_ARM ]; then
    echo "arm toolchain is already built."
else
    $ANDROID_NDK/build/tools/make-standalone-toolchain.sh --platform=android-14 --install-dir=$TOOLCHAIN_ARM
fi

if [ -d $TOOLCHAIN_X86 ]; then
    echo "x86 toolchain is already built."
else
    $ANDROID_NDK/build/tools/make-standalone-toolchain.sh --platform=android-14 --arch=x86 --install-dir=$TOOLCHAIN_X86
fi


if [ -d $X264_SOURCE ]; then
    echo "libx264 is already cloned."
else
    git submodule update --init
fi

if [ -d ffmpeg ]; then
  echo "ffmpeg is already cloned and patched."
  cd ffmpeg
else
  git clone git://source.ffmpeg.org/ffmpeg.git ffmpeg
  cd ffmpeg

  git reset --hard
  git clean -f -d
  git checkout `cat ../ffmpeg-version`
  patch -p1 <../FFmpeg-VPlayer.patch
  [ $PIPESTATUS == 0 ] || exit 1

  git log --pretty=format:%H -1 > ../ffmpeg-version
fi


for version in neon x86; do
  case $version in
    neon)
      TOOLCHAIN_PREFIX=arm-linux-androideabi
      TARGET_ARCH=arm
      TARGET_ARCH_X264=arm
      EXTRA_CFLAGS="$EXTRA_ARM_CFLAGS -march=armv7-a -mfpu=neon -mfloat-abi=softfp -mvectorize-with-neon-quad"
      EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"
      LIB_SUB="armeabi-v7a"
      ;;
    armv7)
      TOOLCHAIN_PREFIX=arm-linux-androideabi
      TARGET_ARCH=arm
      TARGET_ARCH_X264=arm
      EXTRA_CFLAGS="$EXTRA_ARM_CFLAGS -march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp"
      EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"
      LIB_SUB="armeabi-v7a"
      ;;
    vfp)
      TOOLCHAIN_PREFIX=arm-linux-androideabi
      TARGET_ARCH=arm
      TARGET_ARCH_X264=arm
      EXTRA_CFLAGS="$EXTRA_ARM_CFLAGS -march=armv6 -mfpu=vfp -mfloat-abi=softfp"
      EXTRA_LDFLAGS=""
      ;;
    armv6)
      TOOLCHAIN_PREFIX=arm-linux-androideabi
      TARGET_ARCH=arm
      TARGET_ARCH_X264=arm
      EXTRA_CFLAGS="$EXTRA_ARM_CFLAGS -march=armv6"
      EXTRA_LDFLAGS=""
      ;;
     x86)
      TOOLCHAIN_PREFIX=i686-linux-android
      TARGET_ARCH=x86
      TARGET_ARCH_X264=i686
      EXTRA_CFLAGS="-mtune=atom -mssse3 -mfpmath=sse"
      EXTRA_LDFLAGS=""
      EXTRA_FFMPEG_FLAGS="--disable-avx"
      LIB_SUB="x86"
      ;;
    *)
      EXTRA_CFLAGS=""
      EXTRA_LDFLAGS=""
      ;;
  esac

  export CC="ccache $TOOLCHAIN_PREFIX-gcc"
  export LD=$TOOLCHAIN_PREFIX-ld
  export AR=$TOOLCHAIN_PREFIX-ar

  X264_PREFIX="$X264_DEST/$version" && mkdir -p $X264_PREFIX

if [ -f $X264_DEST/$version/lib/libx264.a ]; then
    echo "libx264.a ($TARGET_ARCH) is already built."
else
    echo "configure and make x264"
    cd $X264_SOURCE
   ./configure --cross-prefix=$TOOLCHAIN_PREFIX- --prefix=$X264_PREFIX --host=$TARGET_ARCH_X264-linux $X264_FLAGS --extra-cflags="$CFLAGS $EXTRA_CFLAGS" | tee $X264_PREFIX/configuration.txt
    make clean
    make -j4 STRIP= || exit 1
    make install || exit 1
fi

  PREFIX="$DEST/$version" && mkdir -p $PREFIX

  cd $SOURCE
  echo "Configure ffmpeg for $version."
  ./configure --prefix=$PREFIX --arch=$TARGET_ARCH --cross-prefix=$TOOLCHAIN_PREFIX- $FFMPEG_FLAGS $EXTRA_FFMPEG_FLAGS --extra-cflags="$CFLAGS $EXTRA_CFLAGS -I$X264_PREFIX/include" --extra-ldflags="$EXTRA_LDFLAGS -L$X264_PREFIX/lib" | tee $PREFIX/configuration.txt
  cp config.* $PREFIX
  [ $PIPESTATUS == 0 ] || exit 1

  make clean
  make -j4 || exit 1
  make install || exit 1

  rm libavcodec/inverse.o

 #mv ../libs/armeabi ../libs/$LIB_SUB
  #$CC -lm -lz -shared --sysroot=$SYSROOT -Wl,--no-undefined -Wl,-z,noexecstack $EXTRA_LDFLAGS libavutil/*.o libavutil/arm/*.o libavcodec/*.o libavcodec/arm/*.o libavformat/*.o libswresample/*.o libswscale/*.o -o $PREFIX/libffmpeg.so

  #cp $PREFIX/libffmpeg.so $PREFIX/libffmpeg-debug.so
  #arm-linux-androideabi-strip --strip-unneeded $PREFIX/libffmpeg.so
done 

  cd ..
  $ANDROID_NDK/ndk-build -d -e APP_ABI="armeabi-v7a x86" LOCAL_ARM_NEON=true
 
