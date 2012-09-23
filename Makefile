# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, Saab AB
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
__bobPLUGINDIR  := $(BOBHOME)/plugins
__bobPLUGININIT := makeinit.mk
__bobPLUGINPOST := makepostprocess.mk
__bobPLUGINHEAD := makeheader.mk
__bobPLUGINFOOT := makefooter.mk
BOBPLUGINS      := $(BOBPLUGINS) dotgraph test qacpp xsd

# Other configuration variables.
override empty :=
override space := $(empty) $(empty)
override comma := ,

# Files used for various purposes.
HEADER_BUILD := $(BOBHOME)/makeheader.mk
FOOTER_BUILD := $(BOBHOME)/makefooter.mk
HEADER_INFO  := $(BOBHOME)/makeheader_info.mk
FOOTER_INFO  := $(BOBHOME)/makefooter_info.mk
RULES        := makerules.mk
INFOS        := makeinfo.mk

# Make these files phony, we don't want make to consider these.
.PHONY: \
	$(HEADER_BUILD) \
	$(FOOTER_BUILD) \
	$(HEADER_INFO) \
	$(FOOTER_INFO)
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
export MACHINE  ?= $(shell uname -m)


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

# Havings and no havings. The existance of some commands turns on some extra
# targets, not really necessary for normal operaion.
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

# Exceptions for SunOS.
ifeq "$(PLATFORM)" "SunOS"
export INSTALL          := $(shell type -p ginstall)
export __bobFIND        := $(shell type -p gfind)
ifeq "$(firstword $(INSTALL))" "no"
$(error No ginstall available)
endif
endif
# ******************************************************************************


# Compiler, build and linktypes.
# ******************************************************************************
# Default to using gcc, (changing is easy). Default buildtype SHALL always be
# release. The reason for that is that the simplest and most non-altered build
# process shall produce a releaseable software product, not a developer debug
# invested built monster.
compiler  ?= gcc
buildtype ?= release
linktype  ?= default
# Map to "private" variable.
export __bobCOMPILER  := $(compiler)
export __bobBUILDTYPE := $(buildtype)
export __bobLINKTYPE  := $(linktype)

# Include compiler file, complain if it does not exist.
__bob_compiler_file := $(wildcard $(BOBHOME)/Makefile.compiler.$(compiler).mk)
ifdef __bob_compiler_file
include $(__bob_compiler_file)
else
__bob_available_compilers := \
	$(patsubst Makefile.compiler.%.mk,%,$(notdir $(wildcard $(BOBHOME)/Makefile.compiler.*.mk)))
$(info $(W_PREFIX) Available compilers are $(__bob_available_compilers))
$(error Unknown compiler $(__bobCOMPILER))
endif

# Santity check the buildtype.
$(if $(findstring $(__bobBUILDTYPE),$(COMPILER_BUILDTYPES)),,\
	$(info $(W_PREFIX) Available buildtypes for $(__bobCOMPILER) are: $(COMPILER_BUILDTYPES)) \
	$(error Unknown buildtype $(__bobBUILDTYPE)))

# Sanity check the linktype.
$(if $(findstring $(__bobLINKTYPE),$(COMPILER_LINKTYPES)),,\
	$(info $(W_PREFIX) Available linktypes for $(__bobCOMPILER) are: $(COMPILER_LINKTYPES)) \
	$(error Unknown linktype $(__bobLINKTYPES)))
# ******************************************************************************


# Source and build directory base references, user setable.
# ******************************************************************************
# The source directory is actually pwd, and for a software project (module) it
# is the top directory holding the source code etc. Setting this to something
# else may have little or no practical use.
ifdef srcdir
override srcdir := $(abspath $(srcdir))
else
srcdir := $(abspath .)
endif

# The build directory is the base directory for object and target artifacts
# directories. The feature is that this can be pointed to /var/tmp (or
# similiar) while still having the code checked out on a "safe but slow"
# NFS-filesystem.
ifdef builddir
override builddir := $(abspath $(builddir))
else
builddir := $(abspath .)
endif
# ******************************************************************************


# Installation directory configuration
# ******************************************************************************
ifdef DESTDIR
override DESTDIR := $(abspath $(DESTDIR))/
else
DESTDIR :=
endif

ifdef prefix
override prefix := $(abspath $(prefix))
else
prefix := /opt/saab
endif

exec_prefix     ?= $(prefix)
bindir          ?= $(exec_prefix)/bin
sbindir         ?= $(exec_prefix)/sbin
libdir          ?= $(exec_prefix)/lib
libexecdir      ?= $(exec_prefix)/libexec
sysconfdir      ?= $(prefix)/etc
includedir      ?= $(prefix)/include
datarootdir     ?= $(prefix)/share
datadir         ?= $(datarootdir)
docdir          ?= $(datarootdir)/doc
mandir          ?= $(datarootdir)/man
localstatedir   ?= $(prefix)/var
man1dir         ?= $(mandir)/man1
applicationsdir ?= $(datadir)/applications
# ******************************************************************************


# Fix recipe path. The recipe is a file taken on the command line, and might
# as such not always exist, and due to technical problems the base path were
# the file is actually used might vary because of meta or build mode. thus we
# must provide an absolute path as soon as possible.
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
# connected. Target 'install' depends on 'all' etc.
ifdef BOB.BUILD_TEST
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
