#!/bin/sh

set -e
set -x

if [ -z "$APPVEYOR_BUILD_FOLDER" ]; then
	echo "ERROR: APPVEYOR_BUILD_FOLDER not set"
	exit 1
fi

export DEBIAN_FRONTEND=noninteractive

export VID=0x1d50
export PID_RT=0x5037
export PID_DFU=0x5038
export MAKE_ARGS="-j V=1"
export BOOTLOADER_NAME="D5035-50 slLIN DFU"
export TARGET_DIR=$APPVEYOR_BUILD_FOLDER/tmp



# install build dependencies
sudo apt-get update && sudo apt-get install -y dfu-util gcc-arm-none-eabi pixz python3

# init submodules
git submodule update --init --depth 1 --recursive

env

# Save current commit
mkdir -p $TARGET_DIR/sllin
echo $APPVEYOR_REPO_COMMIT >$TARGET_DIR/sllin/COMMIT

############
# D5035-50 #
############
hw_revs=1
export BOARD=d5035_50

# make output dirs for hw revs
for i in $hw_revs; do
	mkdir -p $TARGET_DIR/sllin/$BOARD/0$i
done



# SuperDFU
project=atsame51_dfu
cd $APPVEYOR_BUILD_FOLDER/Boards/examples/device/${project}


for i in $hw_revs; do
	make $MAKE_ARGS BOARD=$BOARD BOOTLOADER=1 VID=$VID PID=$PID_DFU PRODUCT_NAME="$BOOTLOADER_NAME" INTERFACE_NAME="$BOOTLOADER_NAME" HWREV=$i
	cp _build/$BOARD/${project}.hex $TARGET_DIR/sllin/$BOARD/0$i/superdfu.hex
	cp _build/$BOARD/${project}.bin $TARGET_DIR/sllin/$BOARD/0$i/superdfu.bin
	rm -rf _build
	make $MAKE_ARGS BOARD=$BOARD BOOTLOADER=1 VID=$VID PID=$PID_DFU PRODUCT_NAME="$BOOTLOADER_NAME" INTERFACE_NAME="$BOOTLOADER_NAME" HWREV=$i APP=1 dfu
	cp _build/$BOARD/${project}.dfu $TARGET_DIR/sllin/$BOARD/0$i/superdfu.dfu
	rm -rf _build
done

# sllin
project=sllin
cd $APPVEYOR_BUILD_FOLDER/Boards/examples/device/${project}


for i in $hw_revs; do
	make $MAKE_ARGS HWREV=$i
	cp _build/$BOARD/${project}.hex $TARGET_DIR/sllin/$BOARD/0$i/sllin-standalone.hex
	cp _build/$BOARD/${project}.bin $TARGET_DIR/sllin/$BOARD/0$i/sllin-standalone.bin
	rm -rf _build
	make $MAKE_ARGS HWREV=$i APP=1 dfu
	cp _build/$BOARD/${project}.superdfu.hex $TARGET_DIR/sllin/$BOARD/0$i/sllin-dfu.hex
	cp _build/$BOARD/${project}.superdfu.bin $TARGET_DIR/sllin/$BOARD/0$i/sllin-dfu.bin
	cp _build/$BOARD/${project}.dfu $TARGET_DIR/sllin/$BOARD/0$i/sllin.dfu
	rm -rf _build
done
unset hw_revs


######################
# Other Boards (uf2) #
######################

boards="trinket_m0"
for board in $boards; do
	export BOARD=$board

	mkdir -p $TARGET_DIR/sllin/$BOARD

	make $MAKE_ARGS uf2

	cp _build/$BOARD/${project}.uf2 $TARGET_DIR/sllin/$BOARD/
	rm -rf _build
done


# archive
cd $TARGET_DIR && (tar c sllin | pixz -9 >sllin-firmware.tar.xz)

