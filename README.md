# tinyos-wrappers
TinyOS wrapping code for other frameworks (e.g., Atmel Software Framework or Stm32Cube). Check the wiki here: https://github.com/ucolesanti/tinyos-wrappers/wiki to learn more about the current port status, to learn how to configure several peripherals and to understand how the port works.

Currently supported platforms:

- Atmel Xplained Pro boards: SamD20, SamD21, SamR21, SamW25
- STMicroelectronics Discovery boards: 32L476Discovery
- STMicroelectronics Nucleo boards: Nucleo-L476RG

Planned:
- Atmel Xplained Pro boards: SamL21, SamC21
- Atmel Xplained Mini boards: SamD10, SamD11

# Watch YouTube videos
- RadioCountToLeds on SamR21Xpro and SamD21Xpro: https://youtu.be/oHhpAoBjUlI
- RadioCountToLeds on Nucleo476 and SamR21Xpro: https://youtu.be/ORClH4oxV6s
- Low Power Listening current measurement on SamR21Xpro: https://youtu.be/8AEeWWkAXQA

# Getting Started
1 - make sure to have a proper tinyos-main installation and that you have an arm compiler installed (I used gcc-arm-none-eabi package from debian jessie repository (4.8.1-1) )

2 - clone this git wherever you want

3 - download the Atmel Software Framework (currently supported version: 3.32.0.48) and extract the xdk-asf-3.32.0 folder in tos/chips/cortex/sam. Then download the Stm32L4 framework (currently supported version: V.1.5.0) and extract the STM32L4xx_HAL_Driver folder in tos/chips/cortex/stm32l4

4 - for the Atmel Software Framework, copy the content of the patch-xdk-asf-3.32.0 in the xdk-asf-3.32.0 folder and overwrite all the modified files. For the Stm32Cube framework, select the STM32L4xx_HAL_Driver folder and replace all occurences of the keywork SUCCESS with HAL_SUCCESS (enable case sensitive search first)

5 - create a Makefile.include in the root directory that includes the following code:
```
TINYOS_ROOT_DIR=path_to_tinyos_main
include $(TINYOS_ROOT_DIR)/Makefile.include
```
6 - create a tinyos.sh bash script that includes the following code:
```
#!/bin/bash
TINYOS_ROOT_DIR_ADDITIONAL=your_contrib_path
export TINYOS_ROOT_DIR_ADDITIONAL
```
7 - run "source tinyos.sh" to set environment variables

8 - go in your tinyos-main/apps/Blink directory and try to compile one of the supported platforms by typing:
```
make your_platform
```
where "your_platform" can be: samd20xpro | samd21xpro | samr21xpro | samw25xpro | disco476 | nucleo476

9 - check if it works, if yes, try to program the board:

for Atmel Xplained boards just type:
```
make your_platform reinstall,1
```
for STM Nucleo or discovery boards copy the tinyos-main/apps/Blink/build/your_platform/main.bin file in the mass storage created by the ST-Link interface.

10 - perform the same test for RadioCountToLeds. Note that RadioCountToLeds requires a radio transceiver. The only platform with integrated radio transceiver is the samr21xpro, for all other platforms you need to plug a suppported transceiver and type:

```
make your_platform your_supported_transceiver
```
where "your_supported_transceiver" can be: reb233xpro | zigbitrf212

If you forget to specify a transceiver on a platform other than samr21xpro, the compiler will generate several errors for the missing wireless library.

# Common issues
- For Atmel boards, you could have some permission problems when trying to program the board through the edbg chip. The edbg programming tool (which is developed by Alex Taradov and can be found here: https://github.com/ataradov/edbg), which I copied in support/make/samxpro/edbg-master, has a file named 90-atmel-edbg.rules which has to be copied in /etc/udev/rules.d to enable programming permissions on Edbg devices (once copied, type "sudo service udev restart" then unplug and replug the device).
