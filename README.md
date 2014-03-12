simple-pin-memory-trace
=======================

## Intro 

该pin插件功能是获取整个程序的访存trace。修改自pin自带的`source/tools/ManualExamples/pinatrace.cpp`
有以下功能扩展：
1. 按线程存储程序的访存trace
1. trace通过zlib压缩
1. 附加了其他一些信息

## How to compile

+ 确认已经安装了libz开发库，ubuntu：`sudo apt-get install zlib1g-dev`
+ 将`pinatrace.cpp`覆盖到你下载的`source/tools/ManualExamples/pinatrace.cpp`，同时将`libgzstream.a`和`gzstream.h`放到相同的目录下面。**注意**附带的libgzstream.a是linux x86 **64bit**下编译的库，因此若系统环境为32bit时需要自行编译`libgzstream.a`替换仓库里的`libgzstream.a`，[参考链接](http://www.cs.unc.edu/Research/compgeom/gzstream/)。
+ 执行`compile-pinatrace.cpp`对`pinatrace.so`进行编译，注意必须要保证目录中存在`gzstream.h`和`libgzstream.a`

脚本内容如下，实际上就是在已有编译命令基础上，链接环节中增加了`-lgzstream`和`-lz`，**注意**脚本中目录`obj-ia32`目录是32位系统的，如果是64位的话，应该改为`obj-intel64`

```bash
#!/bin/bash


g++ -DBIGARRAY_MULTIPLIER=1 -Wall -Werror -Wno-unknown-pragmas -fno-stack-protector -DTARGET_IA32 -DHOST_IA32 -DTARGET_LINUX  -I../../../source/include/pin -I../../../source/include/pin/gen -I../../../extras/components/include -I../../../extras/xed2-ia32/include -I../../../source/tools/InstLib -O3 -fomit-frame-pointer -fno-strict-aliasing -I.  -c -o obj-ia32/pinatrace.o pinatrace.cpp

g++ -shared -Wl,--hash-style=sysv -Wl,-Bsymbolic -Wl,--version-script=../../../source/include/pin/pintool.ver    -o obj-ia32/pinatrace.so obj-ia32/pinatrace.o  -L../../../ia32/lib -L../../../ia32/lib-ext -L../../../ia32/runtime/glibc -L../../../extras/xed2-ia32/lib -lpin -lxed -ldwarf -lelf -ldl -L. -lgzstream -lz
```

### gzstream

在gzstream子目录中可以编译得到本地系统对应的gzstream库，使用`make`即可。

## How to use

pindir：pin目录
output：编译成功后生成的pinatrace.so的目录，其中64位系统时目录名为`obj-intel64`
foo：目标程序，其中也作为生成trace的trace文件前缀，这样生成的trace为`foo-1.gz`，`foo-2.gz`...，其中`1`，`2`为线程区分标识
`/path/to/foo -para1 -para2` 为调用foo程序时的完整路径和参数

`$pindir/pin -injection child -t $pindir/source/tools/ManualExamples/$output/pinatrace.so -o foo -- /path/to/foo -para1 -para2 `
