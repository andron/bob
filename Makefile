# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
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
__bob.plugin.dir  := $(BOBHOME)/plugins
__bob.plugin.init := makeinit.mk
__bob.plugin.post := makepostprocess.mk
__bob.plugin.head := makeheader.mk
__bob.plugin.foot := makefooter.mk
BOBPLUGINS      := $(BOBPLUGINS) dotgraph test xsd

# Other configuration variables.
override empty :=
override space := $(empty) $(empty)
override comma := ,

# Files used for various purposes.
__bob.file.headerb := $(BOBHOME)/makeheader.mk
__bob.file.footerb := $(BOBHOME)/makefooter.mk
__bob.file.headeri := $(BOBHOME)/makeheader_info.mk
__bob.file.footeri := $(BOBHOME)/makefooter_info.mk
__bob.file.rules := makerules.mk
__bob.file.infos := makeinfo.mk

# Make these files phony, we don't want make to consider these.
.PHONY: \
	$(__bob.file.headerb) \
	$(__bob.file.footerb) \
	$(__bob.file.headeri) \
	$(__bob.file.footeri)
# ******************************************************************************


# Prefixes for output written by info or error. The prefixes are used to present
# different types of output. All prefixes are themselves prefixed with
# __bob.prefix.
# ******************************************************************************
__bob.prefix := $(space)[$(lastword $(subst /, ,$(dir $(realpath $(firstword $(MAKEFILE_LIST))))))]
PREFIX   := $(__bob.prefix)
D_PREFIX := $(__bob.prefix) //# Debug
W_PREFIX := $(__bob.prefix) !!# Warning
C_PREFIX := $(__bob.prefix) **# Compile
L_PREFIX := $(__bob.prefix) ==# Link
I_PREFIX := $(__bob.prefix) >># Install
T_PREFIX := $(__bob.prefix)   # Text output
X_PREFIX := $(__bob.prefix) TT# Test output
V_PREFIX := $(__bob.prefix) VV# Test output

ifdef buildarch
__bob.buildarch := $(buildarch)
else
__bob.buildarch := $(shell uname -m)
endif

ifeq "$(__bob.buildarch)" "x86_64"
__bob.archlib := lib64
else
__bob.archlib := lib
endif
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

export __bob.cmd.rsync         ?= $(shell type -p rsync) -quplr
export __bob.cmd.rsync_exclude ?= --exclude=.git --exclude=.svn --exclude=CVS --exclude=RCS
export __bob.cmd.rpmbuild      ?= $(shell type -p rpmbuild)
export __bob.cmd.rpm           ?= $(shell type -p rpm)
export __bob.cmd.cppcheck      ?= $(shell type -p cppcheck)
export __bob.cmd.tar           ?= $(shell type -p tar)
export __bob.cmd.ln            ?= $(shell type -p ln) -sf
export __bob.cmd.find          ?= $(shell type -p find)
export __bob.cmd.awk           ?= $(firstword $(shell type -p gawk) $(shell type -p awk))
export __bob.cmd.rm            ?= $(shell type -p rm) -f
export __bob.cmd.rmdir         ?= $(shell type -p rm) -rf
export __bob.cmd.doxygen       ?= $(shell type -p doxygen)
export __bob.cmd.asciidoc      ?= $(shell type -p asciidoc)
export __bob.cmd.install       ?= $(shell type -p install)
export __bob.cmd.install_hdr   ?= $(__bob.cmd.install) -Dm644
export __bob.cmd.moc3          ?= $(firstword $(wildcard $(QT_HOME)/bin/moc)  $(shell type -p moc-qt3))
export __bob.cmd.uic3          ?= $(firstword $(wildcard $(QT_HOME)/bin/uic)  $(shell type -p uic-qt3))
export __bob.cmd.moc4          ?= $(firstword $(wildcard $(QT4_HOME)/bin/moc) $(shell type -p moc-qt4))
export __bob.cmd.uic4          ?= $(firstword $(wildcard $(QT4_HOME)/bin/uic) $(shell type -p uic-qt4))
export __bob.cmd.rcc4          ?= $(firstword $(wildcard $(QT4_HOME)/bin/rcc) $(shell type -p rcc-qt4))
export INSTALL                 ?= $(__bob.cmd.install)
export INSTALL_EXEC            ?= $(__bob.cmd.install) -Dm755
export INSTALL_DATA            ?= $(__bob.cmd.install) -Dm644
export INSTALL_DIRS            ?= $(__bob.cmd.install) -d
export INSTALL_FILES           ?= $(__bob.cmd.rsync) $(__bob.cmd.rsync_exclude)

# Havings and no havings. The existance of some commands turns on some extra
# targets, not really necessary for normal operaion.
ifneq "$(__bob.cmd.rpmbuild)" ""
override __bob_have_feature_rpm := 1
endif
ifneq "$(__bob.cmd.tar)" ""
override __bob_have_feature_tar := 1
endif
ifneq "$(__bob.cmd.doxygen)" ""
override __bob_have_feature_doxygen := 1
endif
ifneq "$(__bob.cmd.cppcheck)" ""
override __bob_have_feature_cppcheck := 1
export CPPCHECKFLAGS ?= -q --enable=style --suppress="missingInclude"
endif
# ******************************************************************************


# Build architecture
# ******************************************************************************
# Variable buildarch have no default, default is to use machine arch. Its use
# is mostly/only for building 32-bit software on 64-bit machines.
export __bob.buildarch ?= $(buildarch)
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
export __bob.compiler  := $(compiler)
export __bob.buildtype := $(buildtype)
export __bob.linktype  := $(linktype)

# Include compiler file, complain if it does not exist.
__bob_compiler_file := $(wildcard $(BOBHOME)/Makefile.compiler.$(compiler).mk)
ifdef __bob_compiler_file
include $(__bob_compiler_file)
else
__bob_available_compilers := \
	$(patsubst Makefile.compiler.%.mk,%,$(notdir $(wildcard $(BOBHOME)/Makefile.compiler.*.mk)))
$(info $(W_PREFIX) Available compilers are $(__bob_available_compilers))
$(error Unknown compiler $(__bob.compiler))
endif

# Santity check the buildtype.
$(if $(findstring $(__bob.buildtype),$(COMPILER_BUILDTYPES)),,\
	$(info $(W_PREFIX) Available buildtypes for $(__bob.compiler) are: $(COMPILER_BUILDTYPES)) \
	$(error Unknown buildtype $(__bob.buildtype)))

# Sanity check the linktype.
$(if $(findstring $(__bob.linktype),$(COMPILER_LINKTYPES)),,\
	$(info $(W_PREFIX) Available linktypes for $(__bob.compiler) are: $(COMPILER_LINKTYPES)) \
	$(error Unknown linktype $(__bob.linktypeS)))
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


# Default target definitions
# ******************************************************************************
# Default target is to say that there is no such target.
.DEFAULT:
	@echo " $(__bob.prefix) No target \"$@\""
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
__bob.prefix := " [bob]"
bob.package:
	@echo "$(__bob.prefix) Creating BOB-package from $(BOBHOME)"; \
	$(__bob.cmd.tar) -C $${BOBHOME%/*} \
		--exclude "*/.git*" \
		--exclude "*/.svn*" \
		--exclude "*~" \
		-pzcf $(PWD)/$@.tar.gz $${BOBHOME##*/}

bob.info:
	@echo -e \
	"$(__bob.prefix) Path:    $(BOBHOME)\n"\
	"$(__bob.prefix) Plugins: $(strip $(sort $(BOBPLUGINS)))"

ifneq "$(__bob.cmd.asciidoc)" ""
bob.doc: DOCS.html
DOCS.html: DOCS
	@echo "$(__bob.prefix) Creating Asciidoc from $<"; \
	$(__bob.cmd.asciidoc) -a toc -a max-width=85ex -d article -b html5 $<;

endif

else
# Extract name, version and release, the N,V,R tuple, from the makerules.mk
# file. If that file does not exist. Try finding makerules.mk files in
# subdirectories, then start a meta build project.
# ******************************************************************************
ifneq "$(firstword $(wildcard $(__bob.file.rules)))" ""
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
