simple-pin-memory-trace
=======================

## Intro 

该pin插件功能是获取整个程序的访存trace。修改自pin自带的`source/tools/ManualExamples/pinatrace.cpp`
有以下功能扩展：
1. 按线程存储程序的访存trace
1. trace通过zlib压缩
1. 附加了其他一些信息

## How to compile

+ 将`pinatrace.cpp`覆盖到你下载的`source/tools/ManualExamples/pinatrace.cpp`，同时将`libgzstream.a`和`gzstream.h`放到相同的目录下面。**注意**附带的libgzstream.a是linux x86 **64bit**下编译的库，因此若系统环境为32bit时需要自行编译`libgzstream.a`替换仓库里的`libgzstream.a`，[参考链接](http://www.cs.unc.edu/Research/compgeom/gzstream/)。
+ 参考修改makefile，主要是以下代码

```makefile
$(TOOLS): %$(PINTOOL_SUFFIX) : %.o
  ${PIN_LD} $(PIN_LDFLAGS) $(LINK_DEBUG) ${LINK_OUT}$@ $< ${PIN_LPATHS} $(PIN_LIBS) -L. -lgzstream -lz $(DBG)
```

+ 之后编译整个目录（在`source/tools/ManualExamples/`下执行`make`）

## How to use

pindir：pin目录
output：编译成功后生成的pinatrace.so的目录，其中64位系统时目录名为`obj-intel64`
foo：目标程序，其中也作为生成trace的trace文件前缀，这样生成的trace为`foo-1.gz`，`foo-2.gz`...，其中`1`，`2`为线程区分标识
`/path/to/foo -para1 -para2` 为调用foo程序时的完整路径和参数

$pindir/pin -injection child -t $pindir/source/tools/ManualExamples/$output/pinatrace.so -o foo -- /path/to/foo -para1 -para2 
