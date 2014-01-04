#!/bin/bash

if [ $(basename `pwd`) != "lichee" ] ; then
    echo "Please run at the top directory of lichee"
    exit 1
fi

LICHEE_DIR=`pwd`
LINUX_DIR="${LICHEE_DIR}/linux-sunxi"
OUT_DIR="${LICHEE_DIR}/out"
PACK_DIR="${LICHEE_DIR}/tools/pack"


function pack_info()
{
    echo -e "\033[47;30mINFO: $*\033[0m"
}

build_bootimg()
{
	pack_info "Build boot.img"	
	
	arm-linux-gnueabi-objcopy -R .note.gnu.build-id -S -O binary vmlinux bImage
	${LICHEE_DIR}/tools/pack/pctools/linux/android/mkbootimg    \
 		--kernel bImage \
        	--ramdisk rootfs.cpio.gz \
        	--board 'sun7i' \
        	--base 0x40000000 \
        	-o boot.img
	
	rm -rf bImage
	
	if [ ! -e boot.img ]; then
	    echo '*build boot.img fail'
	    exit 1
	fi
	mv boot.img ${OUT_DIR}/linux/common/

	pack_info "Finish build boot.img"	
}

build_kernel()
{
	pack_info "Start compile kernel"	
	
	make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- uImage modules
	
	if [ ! -e vmlinux ]; then
	    echo '*build Kernel fail'
	    exit 1
	fi

	pack_info "Finish compile kernel"
}


if [ ! -e out ]; then
    mkdir -p out/linux/common   
fi

cd ${LINUX_DIR}
build_kernel
build_bootimg

cd ${PACK_DIR}
./pack
