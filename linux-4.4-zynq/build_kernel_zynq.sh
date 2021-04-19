#!/bin/bash
. ~/.bashrc
source ${XILINX_ROOT}/Vivado/${XILINX_VER}/settings64.sh
export ARCH=arm
export CROSS_COMPILE="arm-xilinx-linux-gnueabi-"
make kmax_storage_defconfig
make UIMAGE_LOADADDR=0x8000 uImage

# The arch/arm/boot/uImage is the OS image
