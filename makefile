##
## PIN tools makefile for Linux
##
## For Windows instructions, refer to source/tools/nmake.bat and
## source/tools/Nmakefile
## 
## To build the examples in this directory:
##
##   cd source/tools/ManualExamples
##   make all
## 
## To build and run a specific example (e.g., inscount0)
##   
##   cd source/tools/ManualExamples
##   make dir inscount0.test
##
## To build a specific example without running it (e.g., inscount0)
##   
##   cd source/tools/ManualExamples
##   make dir obj-intel64/inscount0.so
##
## The example above applies to the Intel(R) 64 architecture.
## For the IA-32 architecture, use "obj-ia32" instead of 
## "obj-intel64".
##

##############################################################
#
# Here are some things you might want to configure
#
##############################################################

TARGET_COMPILER?=gnu
ifdef OS
    ifeq (${OS},Windows_NT)
        TARGET_COMPILER=ms
    endif
endif

##############################################################
#
# include *.config files
#
##############################################################

ifeq ($(TARGET_COMPILER),gnu)
    include ../makefile.gnu.config
    CXXFLAGS ?= -Wall -Werror -Wno-unknown-pragmas $(DBG) $(OPT)
	#PIN_LDFLAGS := -L.
	#PIN_LIBS := -lgzstream -lz
endif

ifeq ($(TARGET_COMPILER),ms)
    include ../makefile.ms.config
    DBG?=
endif

##############################################################
#
# Tools sets
#
##############################################################


TOOL_ROOTS = inscount0 inscount1 inscount2 proccount imageload staticcount 
ifeq ($(DETACH_SUPPORTED), yes)
    TOOL_ROOTS += detach
endif
TOOL_ROOTS += malloctrace malloc_mt inscount_tls stack-debugger 
STATIC_TOOL_ROOTS =
APPS = fibonacci

# pinatrace and itrace currently hang cygwin gnu windows
ifneq ($(TARGET_OS),w)
    TOOL_ROOTS += pinatrace itrace
    APPS += fork_app follow_child_app1 follow_child_app2
else
    ifeq ($(TARGET),ia32)
        TOOL_ROOTS += emudiv
        DIVTEST = divide_by_zero_win.exe
        APPS += $(DIVTEST)
    endif
    TOOL_ROOTS += replacesigprobed w_malloctrace buffer-win
    ifneq ($(TARGET_COMPILER),gnu)
        TOOL_ROOTS += pinatrace itrace
    endif
    THREADTEST = thread_win.exe
    #LITTLEMALLOC = little_malloc.exe
    APPS += $(THREADTEST) $(LITTLEMALLOC) 
endif

ifeq (${TARGET_OS},l)
    TOOL_ROOTS += strace
ifneq ($(TARGET),ipf)
    DIVTEST = divide_by_zero_lin
    TOOL_ROOTS += buffer-lin fork_jit_tool follow_child_tool emudiv
    APPS += $(DIVTEST)
    # probe mode requires special libraries to be installed on Linux.
    ifeq ($(PROBE),1)
        TOOL_ROOTS += replacesigprobed
    endif
endif
    STATIC_TOOL_ROOTS += statica
    THREADTEST = thread_lin
    #LITTLEMALLOC = little_malloc
    APPS += $(THREADTEST) $(LITTLEMALLOC) fork_app
endif

ifeq (${TARGET_OS},m)
TOOL_ROOTS += strace
STATIC_TOOL_ROOTS += statica
endif

ifeq ($(TARGET),ia32)
TOOL_ROOTS += isampling safecopy invocation countreps
endif

ifeq ($(TARGET),ia32e)
TOOL_ROOTS += isampling safecopy invocation countreps
endif

# Tools which are built specially, e.g. with more than one source file.
# As well as being defined here they need specific build rules for the tool.
SPECIAL_TOOL_ROOTS = 

TOOLS = $(TOOL_ROOTS:%=$(OBJDIR)%$(PINTOOL_SUFFIX))
STATIC_TOOLS = $(STATIC_TOOL_ROOTS:%=$(OBJDIR)%$(SATOOL_SUFFIX))
SPECIAL_TOOLS = $(SPECIAL_TOOL_ROOTS:%=$(OBJDIR)%$(PINTOOL_SUFFIX))
APPS_BINARY_FILES = $(APPS:%=$(OBJDIR)%)

##############################################################
#
# build rules
#
##############################################################
all: $(OBJDIR)
	-$(MAKE) make_all
tools: $(OBJDIR)
	-$(MAKE) make_tools
apps: $(OBJDIR)
	-$(MAKE) make_apps
test: $(OBJDIR)
	-$(MAKE) make_test

make_all: make_tools make_apps
make_tools: $(TOOLS) $(STATIC_TOOLS) $(SPECIAL_TOOLS)
make_apps: $(APPS_BINARY_FILES)
make_test: $(TOOL_ROOTS:%=%.test) $(STATIC_TOOL_ROOTS:%=%.test) $(SPECIAL_TOOL_ROOTS:%=%.test)


##############################################################
#
# applications
#
##############################################################

$(OBJDIR)thread_lin: thread_lin.c
	$(CC) $(APP_CXXFLAGS) $(PIN_LPATHS) -I../Include -I. -o $@ thread_lin.c -g $(APP_PTHREAD)

$(OBJDIR)thread_win.exe: thread_win.c
	$(CC) $(NO_OPTIMIZE) $(NO_LOGO) $(APP_CXXFLAGS) $(DBG) ${OUTEXE}$@ thread_win.c

$(OBJDIR)divide_by_zero_win.exe: divide_by_zero_win.c
	$(CC) $(NO_OPTIMIZE) $(NO_LOGO) $(APP_CXXFLAGS) $(DBG) ${OUTEXE}$@ divide_by_zero_win.c 

$(OBJDIR)divide_by_zero_lin: divide_by_zero_lin.c
	$(CC) $(NO_OPTIMIZE) $(NO_LOGO) $(APP_CXXFLAGS) $(DBG) ${OUTEXE}$@ $< 
        
$(OBJDIR)little_malloc: little_malloc.c
	$(CC) $(APP_CXXFLAGS) $(PIN_LPATHS) -I../Include -I. -o $@ little_malloc.c -g $(APP_PTHREAD)

$(OBJDIR)little_malloc.exe: little_malloc.c
	$(CC) $(NO_OPTIMIZE) $(NO_LOGO) $(APP_CXXFLAGS) $(DBG) ${OUTEXE}$@ little_malloc.c

$(OBJDIR)fibonacci$(EXEEXT): fibonacci.cpp
	$(CXX) $(APP_CXXFLAGS) $(DBG) $(OUTEXE)$@ fibonacci.cpp

$(OBJDIR)fork_app: fork_app.cpp
	$(CXX) $(APP_CXXFLAGS) $(DBG) $< -o $@

$(OBJDIR)follow_child_app1: follow_child_app1.cpp
	$(CXX) $(APP_CXXFLAGS) $(DBG) $< -o $@

$(OBJDIR)follow_child_app2: follow_child_app2.cpp
	$(CXX) $(APP_CXXFLAGS) $(DBG) $< -o $@


##############################################################
#
# pin tools
#
##############################################################

inscount_tls.test : $(OBJDIR)inscount_tls$(PINTOOL_SUFFIX) $(OBJDIR)$(THREADTEST) inscount_tls.tested inscount_tls.failed
	-$(PIN) -t $< -- ./$(OBJDIR)$(THREADTEST) >  $<.out 2>&1
	rm inscount_tls.failed

malloc_mt.test : $(OBJDIR)malloc_mt$(PINTOOL_SUFFIX) $(OBJDIR)$(THREADTEST) malloc_mt.tested malloc_mt.failed
	-$(PIN) -t $< -- ./$(OBJDIR)$(THREADTEST) >  $<.out 2>&1
	rm malloc_mt.failed


buffer-lin.test : $(OBJDIR)buffer-lin$(PINTOOL_SUFFIX) $(OBJDIR)$(THREADTEST) buffer-lin.tested buffer-lin.failed
	-$(PIN) -t $< -- ./$(OBJDIR)$(THREADTEST) >  $<.out 2>&1
	rm buffer-lin.failed

buffer-win.test : $(OBJDIR)buffer-win$(PINTOOL_SUFFIX) $(OBJDIR)$(THREADTEST) buffer-win.tested buffer-win.failed
	-$(PIN) -t $< -emit 0 -- ./$(OBJDIR)$(THREADTEST) > $<.out 2>&1
	rm buffer-win.failed

invocation.test : $(OBJDIR)invocation$(PINTOOL_SUFFIX) $(OBJDIR)$(LITTLEMALLOC) invocation.tested invocation.failed
	-$(PIN) -t $< -- ./$(OBJDIR)$(LITTLEMALLOC) >  $<.out 2>&1
	rm invocation.failed

# This tool is tested in "Debugger/makefile".  However, leave this line because it is referenced
# in the user manual and used to build the tool.
stack-debugger.test : $(OBJDIR)stack-debugger$(PINTOOL_SUFFIX) $(OBJDIR)fibonacci$(EXEEXT) stack-debugger.tested stack-debugger.failed
	rm stack-debugger.failed

# stand alone pin tool
statica.test: $(OBJDIR)statica$(SATOOL_SUFFIX) statica.tested statica.failed $(OBJDIR)statica
	./$(OBJDIR)statica$(SATOOL_SUFFIX) -i ./$(OBJDIR)statica  > statica.dmp
	rm statica.failed statica.dmp

emudiv.test : $(OBJDIR)emudiv$(PINTOOL_SUFFIX) $(OBJDIR)$(DIVTEST) emudiv.tested emudiv.failed
	$(PIN) -t $< -- ./$(OBJDIR)$(DIVTEST) >  $<.out 2>&1
	grep "Caught divide by zero exception" $<.out
	rm emudiv.failed $<.out

fork_jit_tool.test : $(OBJDIR)fork_jit_tool$(PINTOOL_SUFFIX) $(OBJDIR)fork_app fork_jit_tool.tested fork_jit_tool.failed
	$(PIN) -t $<  -- ./$(OBJDIR)fork_app
	rm fork_jit_tool.failed

follow_child_tool.test: $(OBJDIR)follow_child_tool$(PINTOOL_SUFFIX) $(OBJDIR)follow_child_app1 $(OBJDIR)follow_child_app2 follow_child_tool.failed follow_child_tool.tested
	$(PIN) -follow_execv 1 -t $< -- $(OBJDIR)follow_child_app1 $(OBJDIR)follow_child_app2
	rm follow_child_tool.failed

##############################################################
#
# build rules
#
##############################################################

$(APPS): $(OBJDIR)make-directory

$(OBJDIR)make-directory:
	mkdir -p $(OBJDIR)
	touch $(OBJDIR)make-directory
$(OBJDIR):
	mkdir -p $(OBJDIR)

$(OBJDIR)%.o : %.cpp $(OBJDIR)make-directory
	$(CXX) -c $(CXXFLAGS) $(PIN_CXXFLAGS) ${OUTOPT}$@ $<

$(TOOLS): $(PIN_LIBNAMES)

$(TOOLS): %$(PINTOOL_SUFFIX) : %.o
	${PIN_LD} $(PIN_LDFLAGS) $(LINK_DEBUG) ${LINK_OUT}$@ $< ${PIN_LPATHS} $(PIN_LIBS) -L. -lgzstream -lz $(DBG)

$(STATIC_TOOLS): $(PIN_LIBNAMES)

$(STATIC_TOOLS): %$(SATOOL_SUFFIX) : %.o
	${PIN_LD} $(PIN_SALDFLAGS) $(LINK_DEBUG) ${LINK_OUT}$@ $< ${PIN_LPATHS} $(SAPIN_LIBS) $(DBG)

## cleaning
clean:
	-rm -rf $(OBJDIR) *.out *.log *.tested *.failed *.makefile.copy *.out.*.*
