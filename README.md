# tinyos-wrappers
TinyOS wrapping code for other frameworks (e.g., Atmel Software Framework or Stm32Cube)

# Getting Started
1 - make sure to have a proper tinyos-main installation and you have an arm compiler installed (I used gcc-arm-none-eabi package from debian jessie repository (4.8.1-1) )

2 - clone this git wherever you want

3 - download the atmel software framework (I used the xdk-asf-3.31.0) and put the folder in the tos/chips/cortex/sam folder

4 - copy the content of the patch-xdk-asf-3.31.0 in the xdk-asf-3.31.0 folder and overwrite all the modified files

5 - create a Makefile.include in the root directory pointing your tinyos-main folder (check tinyos on github for instructions)

6 - create a tinyos.sh bash script that includes the following code:
```
#!/bin/bash
TINYOS_ROOT_DIR_ADDITIONAL=your_contrib_path
export TINYOS_ROOT_DIR_ADDITIONAL
```
7 - run "source tinyos.sh" to set environment variables

8 - go in your tinyos-main/apps/Blink directory and try to compile the SamR21 Xplained Pro board by typing: make samr21xpro

9 - check if it works, if yes, try to program the SamR21 Xplained Pro board by typing: make samr21xpro reinstall,1

# Common issues
- You could have some permission problems when trying to program the board. The edbg programming tool (which is developed by Alex Taradov and can be found here: https://github.com/ataradov/edbg), which I copied in support/make/samxpro/edbg-master, has a file name 90-atmel-edbg.rules which has to be copied in /etc/udev/rules.d to enable programming permissions on Edbg devices (once copied, type "sudo service udev restart" then unplug and replug the device.
