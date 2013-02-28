# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

ifndef __bob_compiler_file_included
override __bob_compiler_file_included := 1

# Set CC and CXX variable
override CC  := gcc
override CXX := g++

# Mandatory variables
# ********************************************************************************
COMPILER_VERSION    := $(shell $(CC) -dumpversion)
COMPILER_BUILDTYPES := release debug pedantic profiling
COMPILER_LINKTYPES  := default noundefined
# ********************************************************************************

# Target architecture optimizations
# ********************************************************************************
ifeq "$(findstring i686, $(shell $(CXX) -dumpmachine))" "i686"
export TARGET_ARCH ?= -mtune=generic -msse2 -mfpmath=sse
endif
# ********************************************************************************

# Build types
# ********************************************************************************
# Compiler flags for the different buildtypes, common for both C and C++. If
# special flags are needed for the different languages, those flags should be
# possible to handle manually.
__buildtype_release   := -O2 -g -DNO_DEBUG -DQT_NO_DEBUG
__buildtype_debug     := -O0 -ggdb3 -fno-inline -rdynamic -DDEBUG -DQT_DEBUG
__buildtype_pedantic  := $(__buildtype_release) -pedantic
__buildtype_profiling := -O2 -ggdb3 -pg -DDEBUG -DQT_DEBUG
# Build architecture
__buildarch_i686      := -m32
__buildarch_x86_64    := -m64
# Re-assign and clear with := is to make sure the flags are treated as
# immediate variabels by make. (Subsequent += will assign the value
# immediately).
CFLAGS    := $(__buildarch_$(__bob.buildarch))
CXXFLAGS  := $(__buildarch_$(__bob.buildarch))
GNATFLAGS := $(__buildarch_$(__bob.buildarch))
# Add default compiler flags for all modes.
CFLAGS   += -pipe -fPIC -Wextra -Wall -Wno-long-long -MMD -fno-strict-aliasing -D$(PLATFORM)
CXXFLAGS += -pipe -fPIC -Wextra -Wall -Wno-long-long -MMD -fno-strict-aliasing -D$(PLATFORM)
# Add buildtype flags.
CFLAGS   += $(__buildtype_$(__bob.buildtype))
CXXFLAGS += $(__buildtype_$(__bob.buildtype))
# ********************************************************************************

# Link types
# ********************************************************************************
# Default linkage options, all sub-modules will get these. By default the
# object directory is search for libraries, becasue all the libraries built
# will end up there. Re-assignment is for handling += without overwriting user
# specified flag.
__linktype_default     := -L$(TGTDIR) $(LDFLAGS)
__linktype_noundefined := -L$(TGTDIR) $(LDFLAGS) -Wl,-z,defs
LDFLAGS :=
LDFLAGS += $(__linktype_$(__bob.linktype))
# ********************************************************************************

# Target architecture
# ********************************************************************************
# Assume we have at least sse instructions.
TARGET_ARCH ?= -mtune=generic -msse2 -mfpmath=sse
# ********************************************************************************

# Compiler/Linker specific flags configuration
# ********************************************************************************
_l := -l
_o := -o
_D := -D
_I := -I
_L := -L

DYNAMICLIBFLAG := -shared
AR             := $(shell type -p ar)
ARCREATE       := $(AR) -rcs

ifeq "$(PLATFORM)" "Linux"
SONAMEFLAG          := -Wl,-h<soname>
WHOLEEXTRACTFLAG    := -Wl,-whole-archive
NO_WHOLEEXTRACTFLAG := -Wl,-no-whole-archive
DYNAMICLINKFLAG     := -Wl,-Bdynamic
STATICLINKFLAG      := -Wl,-Bstatic
__bobRPATHLINKFLAG  := -Wl,-rpath-link=
endif

ifeq "$(PLATFORM)" "SunOS"
SONAMEFLAG          := -h<soname>
WHOLEEXTRACTFLAG    := -z allextract
NO_WHOLEEXTRACTFLAG := -z defaultextract
DYNAMICLINKFLAG     := -Wl,-Bdynamic
STATICLINKFLAG      := -Wl,-Bstatic
__bobRPATHLINKFLAG  := -Wl,-R,
endif

# Linux linker demands -rpath-link do find second order library dependencies
override LDFLAGS := $(__bobRPATHLINKFLAG)$(TGTDIR) $(LDFLAGS)
# ********************************************************************************
endif
