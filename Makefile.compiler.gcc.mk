# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Compiler file for GCC
__compiler_name := gcc

# Re-assign and clear with := is to make sure the flags are treated as immediate
# variabels by make. (Subsequent += will assign the value immediately).
CFLAGS   :=
CXXFLAGS :=

# !!!OBS!!!
# Currently mtune=generic is equal to mtune=i686. As soon as this changes,
# i.e. a new compiler assumes that the "generic" set of cpus are much more
# advanced then i686 there might be an issue with the instruction set generated
# by gcc.
ifeq "$(shell uname -m)" "i686"
export TARGET_ARCH ?= -mtune=generic -msse2 -mfpmath=sse
endif

# Compiler flags for the different buildtypes, common for both C and C++. If
# special flags are needed for the different languages, those flags should be
# possible to handle manually.
__gcc_release   := -O2 -g -DQT_NO_DEBUG
__gcc_pedantic  := $(__gcc_release) -pedantic -Wshadow -Wconversion -Wlogical-op
# More specialized
__gcc_debug     := -O0 -ggdb3 -fno-inline -rdynamic -DDEBUG -DQT_DEBUG
__gcc_profiling := -O2 -ggdb3 -pg -DDEBUG -DQT_DEBUG

# Add default compiler flags for all modes.
CFLAGS   += -pipe -fPIC -Wextra -Wall -Wno-long-long -MMD -fno-strict-aliasing -D$(PLATFORM)
CXXFLAGS += -pipe -fPIC -Wextra -Wall -Wno-long-long -MMD -fno-strict-aliasing -D$(PLATFORM)
CFLAGS   += $(__gcc_$(__bobBUILDTYPE))
CXXFLAGS += $(__gcc_$(__bobBUILDTYPE))
# **********************************************************************


# Link types

# Default linkage options, all sub-modules will get these. By default
# the object directory is search for libraries, becasue all the
# libraries built will end up there. Re-assignment is for handling +=
# without overwriting user specified flag.
__gcclink_default     := -L$(TGTDIR) $(LDFLAGS)
__gcclink_noundefined := -L$(TGTDIR) $(LDFLAGS) -Wl,-z,defs
override LDFLAGS      := $(__gcclink_$(__bobLINKTYPE))
# **********************************************************************


# Default libraries to link against. It might be a good idea to put
# libraries that most modules use here, for conveniance.
LIBS := $(LIBS)

COMPILERVERSIONFLAG := --version
DYNAMICLIBFLAG      := -shared

_l := -l
_o := -o
_D := -D
_I := -I
_L := -L

ifeq "$(PLATFORM)" "Linux"
override LDFLAGS    := $(LDFLAGS) -Wl,--as-needed
SONAMEFLAG          := -Wl,-h<soname>
WHOLEEXTRACTFLAG    := -Wl,-whole-archive
NO_WHOLEEXTRACTFLAG := -Wl,-no-whole-archive
DYNAMICLINKFLAG     := -Wl,-Bdynamic
STATICLINKFLAG      := -Wl,-Bstatic
# Linux linker demands -rpath-link do find second order library dependencies
override LDFLAGS    := -Wl,-rpath-link=$(TGTDIR) $(LDFLAGS)
__gcc_rpathnolink   := -Wl,-rpath=
__gcc_rpath         := -Wl,-rpath-link=
endif

ifeq "$(PLATFORM)" "SunOS"
SONAMEFLAG          := -h<soname>
WHOLEEXTRACTFLAG    := -z allextract
NO_WHOLEEXTRACTFLAG := -z defaultextract
DYNAMICLINKFLAG     := -Wl,-Bdynamic
STATICLINKFLAG      := -Wl,-Bstatic
override LDFLAGS    := -Wl,-R,$(TGTDIR) $(LDFLAGS)
__gcc_rpathnolink   := -Wl,-R,
__gcc_rpath         := -Wl,-R,
endif

ifeq "$(PLATFORM)" "Win32"
SONAMEFLAG          :=
WHOLEEXTRACTFLAG    :=
NO_WHOLEEXTRACTFLAG :=
DYNAMICLINKFLAG     :=
STATICLINKFLAG      :=
endif


# Platform dependent, use the path type available.
__bobRPATH := $(__gcc_rpath$(__bobRPATHTYPE))


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
