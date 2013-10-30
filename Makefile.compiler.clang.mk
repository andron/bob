# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Compiler file for Clang
__compiler_name := clang

# Make sure these variables are immediate.
__bobCFLAGS := 
__bobCXXFLAGS := -isystem /sw/gcc/4.7.2-shared/include/c++/4.7.2/
__bobLDFLAGS := -L/sw/gcc/4.7.2-shared/lib/

# !!!OBS!!!
# Currently mtune=generic is equal to mtune=i686. As soon as this changes,
# i.e. a new compiler assumes that the "generic" set of cpus are much more
# advanced then i686 there might be an issue with the instruction set generated
# by clang.
ifeq "$(shell uname -m)" "i686"
export TARGET_ARCH ?= -mtune=generic -msse2
endif

# Compiler flags for the different buildtypes, common for both C and C++. If
# special flags are needed for the different languages, those flags should be
# possible to handle manually.

#TODO find optimization-levels for clang, find clang-specific pedantic options
__clang_release   := -g -DQT_NO_DEBUG
__clang_pedantic  := $(__clang_release) -pedantic -Wshadow -Wconversion
# More specialized
__clang_debug     := -ggdb3 -fno-inline -DDEBUG -DQT_DEBUG
__clang_profiling := -ggdb3 -pg -DDEBUG -DQT_DEBUG
__clang_coverage	:= $(__clang_release) -fprofile-arcs -ftest-coverage

# Add default compiler flags for all modes.
__bobCFLAGS		+= -pipe -fPIC -Wextra -Wall -Wno-long-long -MMD -fno-strict-aliasing -D$(PLATFORM)
__bobCXXFLAGS	+= -pipe -fPIC -Wextra -Wall -Wno-long-long -MMD -fno-strict-aliasing -D$(PLATFORM)
__bobCFLAGS		+= $(__clang_$(__bobBUILDTYPE))
__bobCXXFLAGS	+= $(__clang_$(__bobBUILDTYPE))
# **********************************************************************


# Default libraries to link against. It might be a good idea to put
# libraries that most modules use here, for conveniance.
LIBS := $(LIBS)

COMPILERVERSIONFLAG := --version
DYNAMICLIBFLAG			:= -shared

_l       := -l
_o       := -o
_D       := -D
_I       := -I
_isystem := -isystem
_L       := -L

ifeq "$(PLATFORM)" "Linux"
SONAMEFLAG					:= -Wl,-h<soname>
WHOLEEXTRACTFLAG		:= -Wl,-whole-archive
NO_WHOLEEXTRACTFLAG	:= -Wl,-no-whole-archive
DYNAMICLINKFLAG			:= -Wl,-Bdynamic
STATICLINKFLAG			:= -Wl,-Bstatic
__clang_rpathnolink		:= -Wl,-rpath=
__clang_rpath					:= -Wl,-rpath-link=
endif

ifeq "$(PLATFORM)" "SunOS"
SONAMEFLAG					:= -h<soname>
WHOLEEXTRACTFLAG		:= -z allextract
NO_WHOLEEXTRACTFLAG	:= -z defaultextract
DYNAMICLINKFLAG			:= -Wl,-Bdynamic
STATICLINKFLAG			:= -Wl,-Bstatic
__clang_rpathnolink		:= -Wl,-R,
__clang_rpath					:= -Wl,-R,
endif

ifeq "$(PLATFORM)" "Win32"
SONAMEFLAG					:=
WHOLEEXTRACTFLAG		:=
NO_WHOLEEXTRACTFLAG	:=
DYNAMICLINKFLAG			:=
STATICLINKFLAG			:=
endif


# Platform dependent, use the path type available.
__bobRPATH := $(__clang_rpath$(__bobRPATHTYPE))


# Other platform specific commands.
# **********************************************************************
AR        := $(shell type -p ar)
ARCREATE  := $(AR) -rcs


# Test target to detect compiler
__bobdetectcompiler: __bobdetectCC __bobdetectCXX
__bobdetectCC:
	$(COMPILE.c) -dumpversion  >/dev/null 2>&1 && echo ok
__bobdetectCXX:
	$(COMPILE.cc) -dumpversion >/dev/null 2>&1 && echo ok
