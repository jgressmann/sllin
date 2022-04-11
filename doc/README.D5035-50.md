
# D5035-50 Firmware Update

This assumes you have a board with the SuperDFU bootloader already installed. If not, see below on how to build & flash the bootloader.

## Prequisites

Ensure you have `dfu-util` available on your system. Windows users can [download dfu-util binaries here](http://dfu-util.sourceforge.net/releases/). On a Debian derived distro such as Ubuntu, `apt install dfu-util` will get you set up.

## Flashing

### Linux

#### slLIN
```
sudo dfu-util -d 1d50:5037,:5038 -R -D sllin.dfu
```

#### SuperDFU

```
sudo dfu-util -d 1d50:5037,:5038 -R -D superdfu.dfu
```

_NOTE: You likely need to re-flash the CAN application once the bootloader has been updated._

### Windows

Please follow [these steps](../Windows/README.D5035-50.firmware.flashing.md).

# Building

This section describes the steps to build the software in a Linux-like environment. Windows users should read [this](../Windows/README.D5035-50.firmware.building.md).

## Setup

Clone this repository and initialize the submodules.

```
$ git submodule update --init --recursive
```


## Firmware

slLIN uses a customized [TinyUSB](https://github.com/hathach/tinyusb) stack.

You will need the the ARM GNU toolchain.
On Debian derived Linux distributions `apt-get install gcc-arm-none-eabi` will get you set up.

### Options

You can choose between these options

1. Build and flash stand-alone slLIN
2. Build and flash slLIN and SuperDFU (bootloader)
3. Build and upload slLIN through SuperDFU

If you have a debugger probe such as SEGGER's J-Link you can choose any option. For option 3 you need a board with the SuperDFU bootloader already flashed onto it.

### 1. Build and flash stand-alone slLIN

#### J-Link
```
$ cd Boards/examples/device/sllin
$ make -j V=1 BOARD=d5035_50 HWREV=1 flash-jlink
```

#### Atmel ICE
```
$ cd Boards/examples/device/sllin
$ make -j V=1 BOARD=d5035_50 HWREV=1 flash-edbg
```



This creates and flashes the firmware file. Make sure to replace _HWREV=1_ with the version of the board you are using.

### 2. Build and flash slLIN and SuperDFU (bootloader)

#### Prequisites

Ensure you have `python3` installed.

#### Build & flash

This option installs the SuperDFU  bootloader on the device. SuperDFU implements [USB DFU 1.1](https://usb.org/sites/default/files/DFU_1.1.pdf).

##### J-LINK

```
$ cd Boards/examples/device/atsame51_dfu
$ make -j V=1 BOARD=d5035_50 HWREV=1 BOOTLOADER=1 VID=0x1d50 PID=0x5038 PRODUCT_NAME="D5035-50 slLIN DFU" INTERFACE_NAME="D5035-50 slLIN DFU" flash-jlink
```

##### Atmel ICE

```
$ cd Boards/examples/device/atsame51_dfu
$ make -j V=1 BOARD=d5035_50 HWREV=1 BOOTLOADER=1 VID=0x1d50 PID=0x5038 PRODUCT_NAME="D5035-50 slLIN DFU" INTERFACE_NAME="D5035-50 slLIN DFU" flash-edbg
```

This creates and flashes the bootloader. Make sure to replace _HWREV=1_ with the revision of the board you are using.

Next, flash slLIN using these steps

##### J-LINK

```
$ cd Boards/examples/device/sllin
$ make -j V=1 BOARD=d5035_50 HWREV=1 APP=1 flash-dfu
```


##### Atmel ICE

```
$ cd Boards/examples/device/sllin
$ make -j V=1 BOARD=d5035_50 HWREV=1 APP=1 OFFSET=0x4000 edbg-dfu
```
### 3. Build and upload slLIN through SuperDFU

#### Prequisites

Ensure you have `python3` and `dfu-util` installed.

#### Build

Build the slLIN DFU file

```
$ cd Boards/examples/device/sllin
$ make -j V=1 BOARD=d5035_50 HWREV=1 APP=1 dfu
```

Ensure _HWREV_ matches the board you are using.

Next, upload the DFU file to the board.
```
$ cd Boards/examples/device/sllin
$ sudo dfu-util -R -D _build/d5035_50/sllin.dfu
```