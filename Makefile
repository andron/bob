# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Initialization
# ******************************************************************************
ifndef BOBHOME
BOBHOME := $(abspath .)
else
BOBHOME := $(abspath $(BOBHOME))
endif

.PHONY: $(BOBHOME)/Makefile

# Enabled plugins and plugin files.
__bobPLUGINDIR := $(BOBHOME)/plugins
BOBPLUGINS     := $(BOBPLUGINS) dotgraph test qacpp xsd
PLUGININIT     := makeinit.mk
PLUGINPOST     := makepostprocess.mk
PLUGINHEAD     := makeheader.mk
PLUGINFOOT     := makefooter.mk

# Other configuration variables.
override empty :=
override space := $(empty) $(empty)
override comma := ,

# Files used for various purposes.
HEADER_BUILD	:= $(BOBHOME)/makeheader.mk
FOOTER_BUILD	:= $(BOBHOME)/makefooter.mk
HEADER_INFO		:= $(BOBHOME)/makeheader_info.mk
FOOTER_INFO		:= $(BOBHOME)/makefooter_info.mk
RULES					:= makerules.mk
INFOS					:= makeinfo.mk

.PHONY: \
	$(BOBHOME)/makeheader.mk \
	$(BOBHOME)/makefooter.mk \
	$(BOBHOME)/makeheader_info.mk \
	$(BOBHOME)/makefooter_info.mk
# ******************************************************************************


# Prefixes for output written by info or error. The prefixes are used to present
# different types of output. All prefixes are themselves prefixed with
# __bobPREFIX.
# ******************************************************************************
__bobPREFIX := $(space)[$(lastword $(subst /, ,$(dir $(realpath $(firstword $(MAKEFILE_LIST))))))]
PREFIX   := $(__bobPREFIX)
D_PREFIX := $(__bobPREFIX) //# Debug
W_PREFIX := $(__bobPREFIX) !!# Warning
C_PREFIX := $(__bobPREFIX) **# Compile
L_PREFIX := $(__bobPREFIX) ==# Link
I_PREFIX := $(__bobPREFIX) >># Install
T_PREFIX := $(__bobPREFIX)   # Text output
X_PREFIX := $(__bobPREFIX) TT# Test output
V_PREFIX := $(__bobPREFIX) VV# Test output
# ******************************************************************************


# Options and environment configuration.
# ******************************************************************************
# Store some makeflags into a bob variable.
$(if $(findstring s,$(MAKEFLAGS)),$(eval __bobSILENT:=1))
$(if $(findstring k,$(MAKEFLAGS)),$(eval __bobKEEPGO:=1))
export PLATFORM ?= $(shell uname -s)


# External programs configuration.
# ******************************************************************************
# First of all we must have a proper shell!
override SHELL := $(shell which bash)
ifeq "$(SHELL)" ""
$(error Cannot find bash! Bob must have a proper shell, sorry)
endif

export __bobRSYNC         ?= $(shell type -p rsync) -quplr
export __bobRSYNC_exclude ?= --exclude=.git --exclude=.svn --exclude=CVS --exclude=RCS
export __bobRPMBUILD      ?= $(shell type -p rpmbuild)
export __bobCPPCHECK      ?= $(shell type -p cppcheck)
export __bobTAR           ?= $(shell type -p tar)
export __bobLN            ?= $(shell type -p ln) -sf
export __bobFIND          ?= $(shell type -p find)
export __bobAWK           ?= $(shell type -p gawk)
export __bobSVN           ?= $(shell type -p svn)
export __bobPRINTF        ?= $(shell type -p printf)
export __bobDOXYGEN       ?= $(shell type -p doxygen)
export __bobINSTALL       ?= $(shell type -p install)
export __bobINSTALL_HDR   ?= $(__bobINSTALL) -Dm644
export INSTALL            ?= $(__bobINSTALL)
export INSTALL_EXEC       ?= $(INSTALL) -Dm755
export INSTALL_DATA       ?= $(INSTALL) -Dm644
export INSTALL_DIRS       ?= $(INSTALL) -d
export INSTALL_FILES      ?= $(__bobRSYNC) $(__bobRSYNC_exclude)
export AWK                ?= $(__bobAWK)
export TAR                ?= $(__bobTAR)
export MOC3               ?= $(firstword $(wildcard $(QT_HOME)/bin/moc)  $(shell type -p moc-qt3))
export UIC3               ?= $(firstword $(wildcard $(QT_HOME)/bin/uic)  $(shell type -p uic-qt3))
export MOC4               ?= $(firstword $(wildcard $(QT4_HOME)/bin/moc) $(shell type -p moc-qt4))
export UIC4               ?= $(firstword $(wildcard $(QT4_HOME)/bin/uic) $(shell type -p uic-qt4))
export RCC4               ?= $(firstword $(wildcard $(QT4_HOME)/bin/rcc) $(shell type -p rcc-qt4))

# Havings and no havings ...
ifneq "$(__bobRPMBUILD)" ""
override __bob_have_feature_rpm := 1
endif
ifneq "$(__bobTAR)" ""
override __bob_have_feature_tar := 1
endif
ifneq "$(__bobDOXYGEN)" ""
override __bob_have_feature_doxygen := 1
endif
ifneq "$(__bobCPPCHECK)" ""
override __bob_have_feature_cppcheck := 1
export CPPCHECKFLAGS ?= -q --enable=style --suppress="missingInclude"
endif

# Exception for SunOS.
ifeq "$(PLATFORM)" "SunOS"
export INSTALL          := $(shell type -p ginstall)
export __bobFIND        := $(shell type -p gfind)
ifeq "$(firstword $(INSTALL))" "no"
$(error No ginstall available)
endif
endif
# ******************************************************************************


# We must know the compiler. Default to gcc, i.e. if make says CC is a default
# variable (meaning it has not been explicitly set) we pick gcc as our
# designated source-code mangler. If CC equals CC it cannot have been set
# explicitly and CC is choosen. If CC is the default, gcc will be picked
# anyways. Thus this will be consistent, gcc will be picked unless another
# compiler is set explicitly.
# ******************************************************************************
ifneq "$(origin CC)" "default"
$(info $(PREFIX) Overriding compiler CC=$(CC))
__bobtestcompiler := 1
else
CC=gcc
endif

ifneq "$(origin CXX)" "default"
$(info $(PREFIX) Overriding compiler CXX=$(CXX))
__bobtestcompiler := 1
else
CXX=g++
endif


# Try detecting compiler. This will probably only work for gcc and sparcworks on
# Linux and SunOS.
#
# This will have to go away...
#
# Issue: Both sparcworks and gcc uses cc as their C-compiler. This can give some
# strange behaviours if both g++, gcc and cc is in the path. Setting CXX=g++
# might fail the test since cc might not be gcc cc but Sparcworks cc. In that
# case neither C-compile nor C++-compile test will succeed, resulting in the use
# of default compiler gcc.
$(if $(__bobtestcompiler),\
$(info $(PREFIX) Testing compiler ...)\
$(foreach file,$(wildcard $(BOBHOME)/Makefile.compiler.*.mk),\
	$(if $(COMPILER),,\
	$(eval rval := $(shell $(MAKE) CC=$(CC) CXX=$(CXX) -f $(file) __bobdetectcompiler >/dev/null 2>&1 && echo ok)) \
	$(if $(rval),$(eval override COMPILER := \
		$(patsubst Makefile.compiler.%.mk,%,$(notdir $(file))))))))

# Default values, unless explicitly set we use gcc and g++.
CC				?= gcc
CXX				?= g++
COMPILER	?= gcc
$(if $(__bobtestcompiler),\
	$(info $(PREFIX) Compiler is $(COMPILER) ($(origin COMPILER))))

# Compiler version extraction flags. Notice the simplicity of open source
# (What where Sun thinking?).
__gcc_VERSIONFLAG	:= -dumpversion
__CC_VERSIONFLAG	:= -V 2>&1|head -n1|$(__bobAWK) '{match($$0,"(C|C\\+\\+) ([^ ]+)",a);print a[2]}'
COMPILER_VERSION	:= $(shell $(COMPILER) $(__$(COMPILER)_VERSIONFLAG))
# Ld version, this works for GNU ld and Sun ld, on Windows we need
# updates.
LINKER := $(LD)
# ******************************************************************************


# Build and Link type settings. The user can set buildtype and linktype on the
# command line to adjust the compiler and link flags.
#
# This needs a rework. What should be the default buildtypes if any?
#
# ******************************************************************************
# Build type
buildtype ?= release

# Santity check the value of buildtype.
__bobBUILDTYPES := release debug profiling pedantic
$(if $(findstring $(buildtype),$(__bobBUILDTYPES)),,\
	$(info $(W_PREFIX) Unknown buildtype "$(buildtype)") \
	$(info $(PREFIX) Available buildtypes are: $(__bobBUILDTYPES)) \
	$(error Unknown buildtype $(buildtype)))

# Map the userspace variable name to a bob interal name which can be held more
# static over time, and which might be less possible for a user to use.
export __bobBUILDTYPE := $(buildtype)


# Link type
linktype ?= default

# Santity check
__bobLINKTYPES := default noundefined
$(if $(findstring $(linktype),$(__bobLINKTYPES)),,\
	$(info $(W_PREFIX) Unknown linktype "$(linktype)") \
	$(info $(PREFIX) Available linktypes are: $(__bobLINKTYPES)) \
	$(error Unknown linktype $(linktype)))

# Map to "private" variable.
__bobLINKTYPE := $(linktype)
# ******************************************************************************


# Source and build directory base references, user setable.
# ******************************************************************************
override srcdir   := $(abspath $(if $(srcdir),$(srcdir),.))
override builddir := $(abspath $(if $(builddir),$(builddir),.))
# ******************************************************************************


# Installation directory configuration
# ******************************************************************************
ifdef DESTDIR
override DESTDIR := $(abspath $(DESTDIR))/
else
override DESTDIR :=
endif

ifdef prefix
override prefix := $(abspath $(prefix))
else
prefix := /opt/saab
endif

export exec_prefix     ?= $(prefix)
export bindir          ?= $(exec_prefix)/bin
export sbindir         ?= $(exec_prefix)/sbin
export libdir          ?= $(exec_prefix)/lib
export libexecdir      ?= $(exec_prefix)/libexec
export sysconfdir      ?= $(prefix)/etc
export includedir      ?= $(prefix)/include
export datarootdir     ?= $(prefix)/share
export datadir         ?= $(datarootdir)
export docdir          ?= $(datarootdir)/doc
export mandir          ?= $(datarootdir)/man
export localstatedir   ?= $(prefix)/var
export man1dir         ?= $(mandir)/man1
export applicationsdir ?= $(datadir)/applications
# ******************************************************************************


# Fix recipe path. The recipe is a file taken on the command line, and might as
# such not always exist, and due to technical problems the base path were the
# file is used might vary, thus we must provide an absolute path as soon as
# possible.
# ******************************************************************************
ifdef recipe
MAKEOVERRIDES := $(patsubst recipe=%,recipe=$(abspath $(recipe)),$(MAKEOVERRIDES))
endif


# Default target definitions
# ******************************************************************************
# Default target is to say that there is no such target.
.DEFAULT:
	@echo " $(__bobPREFIX) No target \"$@\""
# Default is to build the all entry, to which all default targets shall be
# connected. Target 'install' depends on 'all'.
ifdef BOB.TEST
default: all test
else
default: all
endif
# ******************************************************************************


# Common (generic) macros.
.PHONY: $(BOBHOME)/Makefile.common.mk
include $(BOBHOME)/Makefile.common.mk


# Bob archive me target, put in a if-else to speed up the archiving procedure.
# ******************************************************************************
ifneq "$(filter bob.%,$(MAKECMDGOALS))" ""
# Use different prefix when in info mode
__bobPREFIX := " [bob]"
bob.package:
	@echo "$(__bobPREFIX) Creating BOB-package from $(BOBHOME)"; \
	$(TAR) -C $${BOBHOME%/*} \
		--exclude "*/.git*" \
		--exclude "*/.svn*" \
		--exclude "*~" \
		-pzcf $(PWD)/$@.tar.gz $${BOBHOME##*/}

bob.info:
	@echo -e \
	"$(__bobPREFIX) Path:    $(BOBHOME)\n"\
	"$(__bobPREFIX) Plugins: $(strip $(sort $(BOBPLUGINS)))"

else
# Extract name, version and release, the N,V,R tuple, from the makerules.mk
# file. If that file does not exist. Try finding makerules.mk files in
# subdirectories, then start a meta build project.
# ******************************************************************************
ifneq "$(firstword $(wildcard $(RULES)))" ""
.PHONY: $(BOBHOME)/Makefile.build.mk
include $(BOBHOME)/Makefile.build.mk
else
.PHONY: $(BOBHOME)/Makefile.meta.mk
include $(BOBHOME)/Makefile.meta.mk
endif
endif


# Trival target to start parsing, used for performance testing.
.PHONY: parseonly
parseonly:;
