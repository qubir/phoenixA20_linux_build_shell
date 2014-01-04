#!/bin/bash

if [ $(basename `pwd`) != "lichee" ] ; then
    echo "Please run at the top directory of lichee"
    exit 1
fi

LICHEE_DIR=`pwd`
UBOOT_DIR="${LICHEE_DIR}/u-boot"
LINUX_DIR="${LICHEE_DIR}/linux-sunxi"
OUT_DIR="${LICHEE_DIR}/out"
PACK_DIR="${LICHEE_DIR}/tools/pack"
ROOTFS_DIR="${LICHEE_DIR}/rootfs"

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

build_uboot()
{
    pack_info "Start compile u-boot"
    make distclean && make sun7i CROSS_COMPILE=arm-linux-gnueabihf-
    pack_info "Finish compile u-boot"
}


if [ ! -e out ]; then
    mkdir -p out/linux/common   
fi

cd ${UBOOT_DIR}
build_uboot

cd ${LINUX_DIR}
build_kernel
build_bootimg

cd ${ROOTFS_DIR}
sudo make -C ${LINUX_DIR} INSTALL_MOD_PATH=`pwd` ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules_install

cd ${PACK_DIR}
./pack
