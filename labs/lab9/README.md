# Starting Files for Lab 9 (Bootstrapping)

This directory contains the starting code files for [Lab 9: Bootstrapping](https://protect.bju.edu/cps/courses/cps230/labs/lab9).

## Contents

* `Makefile`: GNU make recipe for building a bootable image with one command (`make`) (**no changes required**)
* `payload.asm`: the provided second-stage "payload" for the bootloader to load/run (**no changes required**)
* `boot.asm`: the MBR code (**to be completed**) and NASM preprocessor magic to build a bootable floppy image (**no changes required** to non-MBR-code portions of this file)

## Building

If you are working in a Unix-like environment with both `nasm` and GNU `make` installed, simply run `make` in this directory.

If you do not have access to GNU make but do have `nasm` installed/available, run the following commands by hand, in order:

* `nasm -f bin -l payload.lst -o payload.bin payload.asm`
* `nasm -f bin -l boot.lst -o boot.img boot.asm`

*(The `-l <filename>.lst` options are not required, but they produce very helpful "listing" files that can greatly help you with debugging your boot image.)*
