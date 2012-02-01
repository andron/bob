# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Compiler file for cl (VS)
__compiler_name := cl

# Re-assign and clear with := is to make sure the flags are treated as
# immediate variabels by make. (Subsequent += will assign the value
# immediately).
CFLAGS   :=
CXXFLAGS :=


# Compiler flags for the different buildtypes
__cl_release   := /O2 /Zi /D "QT_NO_DEBUG"
__cl_pedantic  := $(__cl_release) 
# More specialized
__cl_debug     := /O0 /Zi /D "DEBUG" /D "QT_DEBUG"
__cl_profiling := /O2 /Zi 


# Add default compiler flags for all modes.
CFLAGS   += /D "$(PLATFORM)"
CXXFLAGS += /D "$(PLATFORM)"
CFLAGS   += $(__cl_$(__bobBUILDTYPE))
CXXFLAGS += $(__cl_$(__bobBUILDTYPE))
# **********************************************************************


# Link types

# Default linkage options, all sub-modules will get these. By default
# the object directory is search for libraries, becasue all the
# libraries built will end up there. Re-assignment is for handling +=
# without overwriting user specified flag.
__cllink_default     := -L$(TGTDIR) $(LDFLAGS)
__cllink_noundefined := -L$(TGTDIR) $(LDFLAGS) -Wl,-z,defs
override LDFLAGS     := $(__cllink_$(__bobLINKTYPE))
# **********************************************************************


# Default libraries to link against. It might be a good idea to put
# libraries that most modules use here, for conveniance.
LIBS := $(LIBS)

COMPILERVERSIONFLAG := --version
DYNAMICLIBFLAG      := -shared

_l := -l
_o := /Fo
_D := /D
_I := /I
_L := -L

ifeq "$(PLATFORM)" "Win32"
SONAMEFLAG          :=
WHOLEEXTRACTFLAG    :=
NO_WHOLEEXTRACTFLAG :=
DYNAMICLINKFLAG     :=
STATICLINKFLAG      :=
endif

ifeq "$(PLATFORM)" "CYGWIN_NT-5.1"

endif

# Platform dependent, use the path type available.
__bobRPATH := $(__cl_rpath$(__bobRPATHTYPE))


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
