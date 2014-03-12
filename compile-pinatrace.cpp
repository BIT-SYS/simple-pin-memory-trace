#!/bin/bash


g++ -DBIGARRAY_MULTIPLIER=1 -Wall -Werror -Wno-unknown-pragmas -fno-stack-protector -DTARGET_IA32 -DHOST_IA32 -DTARGET_LINUX  -I../../../source/include/pin -I../../../source/include/pin/gen -I../../../extras/components/include -I../../../extras/xed2-ia32/include -I../../../source/tools/InstLib -O3 -fomit-frame-pointer -fno-strict-aliasing -I.  -c -o obj-ia32/pinatrace.o pinatrace.cpp

g++ -shared -Wl,--hash-style=sysv -Wl,-Bsymbolic -Wl,--version-script=../../../source/include/pin/pintool.ver    -o obj-ia32/pinatrace.so obj-ia32/pinatrace.o  -L../../../ia32/lib -L../../../ia32/lib-ext -L../../../ia32/runtime/glibc -L../../../extras/xed2-ia32/lib -lpin -lxed -ldwarf -lelf -ldl -L. -lgzstream -lz
