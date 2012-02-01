# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# BOB - Compiler file for Sun CC
__compiler_name := CC

# Default linkage options, all sub-modules will get these. By default
# the object directory is search for libraries, becasue all the
# libraries built will end up there. Re-assignment is for handling +=
# without overwriting user specified flag.
override LDFLAGS := -L$(TGTDIR) $(LDFLAGS)

# Re-assign with := is to make sure the flags are treated as immediate
# variabels by make. (Subsequent += will assign the value
# immediately).
CFLAGS   := $(CFLAGS)
CXXFLAGS := $(CXXFLAGS)

# Compiler flags for the different buildtypes
__CC_release   := -xO4 -DNDEBUG -DQT_NO_DEBUG
__CC_pedantic  := -xO4 -DNDEBUG -DQT_NO_DEBUG +w2
__CC_debug     := -g
__CC_profiling := -xa

# Add default compiler flags for all modes.
CFLAGS   += -KPIC -D'__attribute__(x)=' -D$(PLATFORM)
CXXFLAGS += -KPIC -D'__attribute__(x)=' -D$(PLATFORM)
CFLAGS   += $(__CC_$(__bobBUILDTYPE))
CXXFLAGS += $(__CC_$(__bobBUILDTYPE))
# **********************************************************************


# Default libraries to link against. It might be a good idea to put
# libraries that most modules use here, for conveniance.
LIBS:=$(LIBS)

COMPILERVERSIONFLAG := -V
DYNAMICLIBFLAG      := -G

_D := -D
_I := -I
_L := -L

__CC_rpathnolink := -Wl,-R
__CC_rpath       := -Wl,-R
__bobRPATH       := $(__CC_rpath$(__bobRPATHTYPE))

SONAMEFLAG          := -h<soname>
WHOLEEXTRACTFLAG    := -z allextract
NO_WHOLEEXTRACTFLAG := -z defaultextract
DYNAMICLINKFLAG     := -Bdynamic
STATICLINKFLAG      := -Bstatic
NETWORK_LIBS        := -lsocket -lnsl
MULTITHREADFLAG     := -mt


# Other platform specific commands.
# **********************************************************************
AR       := $(shell type -p ar)
ARCREATE := $(CXX) -xar -o


# Test target to detect compiler
__bobdetectcompiler: __bobdetectCC __bobdetectCXX
__bobdetectCC:
	$(COMPILE.c) -flags >/dev/null 2>&1 && echo ok
__bobdetectCXX:
	$(COMPILE.cc) -V >/dev/null 2>&1 && echo ok
