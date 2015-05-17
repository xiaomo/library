#!/bin/bash

if false ;then
	echo "==========================start repo sync =========================="
	repo sync # 第一次下载android源代码
	while [ $? != 0 ]; do
		echo "==========================sync failed, re-sync again =========================="
		sleep 5
		repo sync # 如果出错，隔2秒后回继续调用repo sync下载android源代码
	done
fi

echo build---------------
export USE_CCACHE=1
#export CCACHE_DIR=/<path_of_your_choice>/.ccache
prebuilts/misc/linux-x86/ccache/ccache -M 100G
#watch -n1 -d prebuilts/misc/linux-x86/ccache/ccache -s
source build/envsetup.sh
lunch aosp_arm-eng
make -j8

echo run----------------
which emulator 
emulator &

