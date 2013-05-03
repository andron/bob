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
override CC  := CC
override CXX := CC

# Mandatory variables
# ********************************************************************************
COMPILER_VERSION    := unknown
COMPILER_BUILDTYPES := release debug
COMPILER_LINKTYPES  := default
# ********************************************************************************

# Build types
# ********************************************************************************
# Compiler flags for the different buildtypes, common for both C and C++. If
# special flags are needed for the different languages, those flags should be
# possible to handle manually.
__buildtype_release   := -xO4 -DNO_DEBUG -DQT_NO_DEBUG
__buildtype_debug     := -g
# Re-assign and clear with := is to make sure the flags are treated as
# immediate variabels by make. (Subsequent += will assign the value
# immediately).
CFLAGS   :=
CXXFLAGS :=
# Add default compiler flags for all modes.
CFLAGS   += -KPIC -D'__attribute__(x)=' -D$(PLATFORM)
CXXFLAGS += -KPIC -D'__attribute__(x)=' -D$(PLATFORM)
# Add buildtype flags
CFLAGS   += $(__buildtype_$(__bob.buildtype))
CXXFLAGS += $(__buildtype_$(__bob.buildtype))
# ********************************************************************************

# Link types
# ********************************************************************************
# Default linkage options, all sub-modules will get these. By default the
# object directory is search for libraries, becasue all the libraries built
# will end up there. Re-assignment is for handling += without overwriting user
# specified flag.
__linktype_default := -L$(TGTDIR) $(LDFLAGS)
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

DYNAMICLIBFLAG := -G
AR             := $(shell type -p ar)
ARCREATE       := $(CXX) -xar -o

SONAMEFLAG          := -h<soname>
WHOLEEXTRACTFLAG    := -z allextract
NO_WHOLEEXTRACTFLAG := -z defaultextract
DYNAMICLINKFLAG     := -Bdynamic
STATICLINKFLAG      := -Bstatic

# Linux linker demands -rpath-link do find second order library dependencies
override LDFLAGS := $(__bobRPATHLINKFLAG)$(TGTDIR) $(LDFLAGS)
# ********************************************************************************
endif
