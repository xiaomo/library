#!/bin/bash
# Program:
#       这个程序用来初始化设置，被~/.bashrc调用
# History:
# V1.0	2015/04/08	moming

alias rm!="/bin/rm"
alias rm=trash
alias lstrash=trash-list

#add by yangkang
export JAVA_HOME="/usr/lib/jvm/java-7-openjdk-amd64"
export PATH="/home/moming/work/media/webrtc/depot_tools:$PATH"

export ANDROID_SDK="/home/moming/work/env/adt-bundle-linux-x86_64-20140702/sdk"
export ANDROID_HOME="$ANDROID_SDK"
export PATH="$ANDROID_SDK:$PATH"
export PATH="$ANDROID_SDK/build-tools/android-4.4w:$PATH"
export PATH="$ANDROID_SDK/platform-tools:$PATH"
export PATH="$ANDROID_SDK/tools:$PATH"
export ANDROID_NDK="/home/moming/work/env/android-ndk-r10d"
export ANDROID_TOOLCHAINS="$ANDROID_NDK/toolchains/arm-linux-androideabi-4.8/prebuilt/linux-x86_64/bin"
export PATH="$ANDROID_NDK:$ANDROID_TOOLCHAINS:$PATH"

export ANDROID_ABI=armeabi-v7a
export BOOST_INC="/home/moming/work/env/boost-android/include"
export BOOST_LIB="/home/moming/work/env/boost-android/lib"

#cd /home/moming/work/
export SVN_EDITOR=/usr/bin/vim
export PATH="/home/moming/work/env/gradle-1.6/bin:$PATH"

export PATH="~/bin:$PATH"
export PATH="~/work/project/breakpad/src/processor/:~/work/project/breakpad/src/tools/linux/dump_syms:$PATH"

if [ "`ls -A ~/kuaipan`" = "" ]; then
  echo "mount kuaipan"
  sudo mount -t cifs -rw -o username=Mo,password=2009cdsf,gid=1000,uid=1000 //192.168.10.57/快盘/ ~/kuaipan
fi

export PATH="~/work/script:$PATH"

echo "backup scipt"
cp ~/work/script/* ~/work/project/library/shell/
cp ~/work/media/webrtc/build.sh ~/work/project/library/shell/webrtc-build-android.sh

echo "+++from ~/work/scipt/setup.sh++"
