# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


#
# Helper target for various purposes. Pure macros should not be defined here,
# all those goes into Makefile.functions.mk.
#


# Bob shell for building and running.
# ******************************************************************************
bobshell: BOBSHELL_BASH_ARGV ?=
bobshell:
	@if [ $$BOBBUILDBASH ]; then \
		echo -e "\nYou are already inside a $@ environment.\n"; \
		exit 0; \
	else \
		LD_LIBRARY_PATH=$(abspath $(TGTDIR)):$$LD_LIBRARY_PATH:$${__bobLISTHOMELIBS// /:}; \
		PATH=$$PATH:$(abspath $(TGTDIR)):$${__bobLISTHOMEBINS// /:}; \
		export LD_LIBRARY_PATH=$${LD_LIBRARY_PATH//::/:}; \
		export PATH=$${PATH//::/:}; \
		export TEST_INCLUDES="$(__bobLISTHOMEINCL)"; \
		export BOBBUILDBASH=1; \
		export MAKELEVEL=0; \
		bash --noprofile --rcfile $(BOBHOME)/bobbashrc $(BOBSHELL_BASH_ARGV); \
	fi;
.PHONY: bobshell
# ******************************************************************************


# Build environment extraction.
# ******************************************************************************
# Create buildinfo.txt (phony, so the file will always be overwritten)
__buildinfofile := buildinfo.txt
distclean clean: __remove_buildinfofile
__remove_buildinfofile:
	@$(__bob.cmd.rm) $(__buildinfofile)
buildinfo: export __name     := $(__name)
buildinfo: export __version  := $(__version)
buildinfo: export __release  := $(__release)
buildinfo: export __group    := $(__group)
buildinfo: export __hostname := $(HOST)
buildinfo: export CXX      := $(CXX)
buildinfo: export CXXFLAGS := $(CXXFLAGS)
buildinfo: export CC       := $(CC)
buildinfo: export CFLAGS   := $(CFLAGS)
buildinfo: export CPPFLAGS := $(CPPFLAGS)
buildinfo: export LD       := $(LD)
buildinfo: export LDFLAGS  := $(LDFLAGS)
buildinfo: export DEFINES  := $(DEFINES)
buildinfo: $(__buildinfofile)
$(__buildinfofile):
	$(BOBHOME)/buildinfo.sh > $@
.PHONY: buildinfo __remove_buildinfofile $(__buildinfofile)
# ******************************************************************************


# Tar file generating target.
# ******************************************************************************
# Generic rule for making a tar.gz file. Uses package destdir as base for all
# its operations. Which must be specified by the dependee target. I.e. the
# target that depends on a tar.gz file must define the variable.  (It is very
# unusual that a developer would need to use this directly).
.PHONY: __remove_packagefile package

ifneq "$(__bob.cmd.tar)" ""

__pkgdir  := $(HOME)/bobpackages
__pkgname := $(__name)-$(__version)
__pkgfile := $(__pkgname).tar.gz
distclean clean: __remove_packagefile
__remove_packagefile:
	@if [ -e $(__pkgdir)/$(__pkgfile) ]; then \
		echo "$(T_PREFIX) Removing package file ..."; \
		$(__bob.cmd.rm) $(__pkgdir)/$(__pkgfile); \
	fi;

# The package target depends on the package file, of course. Though the package
# directory varible has delayed expansion. I.e. it will be expanded when the
# target is actually executed. The rpm section below might need to set the
# package directory to something else.
package: $$(__pkgdir)/$(__pkgfile)

%.tar.gz: __excludetgtobj := $(if $(with_compiled),,--exclude '$(notdir $(TGTBASE))' --exclude '$(notdir $(OBJBASE))')
%.tar.gz: __dependall     := $(if $(with_compiled),all)
%.tar.gz: __pkgflags      := --wildcards -pzcf
%.tar.gz: $$(dir $$@)._INSTALL_DIRECTORY $$(__dependall) __always_build__
	@if [ -L ../$(*F) ]; then                 \
		rm -f ../$(*F); fi;                     \
	if [ ! -e ../$(*F) ]; then                \
		ln -s $(notdir $(shell pwd)) ../$(*F);  \
		linkeddir=1;                            \
	else                                      \
		linkeddir=0;                            \
	fi;                                       \
	echo "$(T_PREFIX) TARFILE $@";            \
	$(__bob.cmd.tar) $(__pkgflags) $@         \
	$(__excludetgtobj)                        \
	--exclude '.svn'                          \
	--exclude '.git'                          \
	--exclude 'CVS'                           \
	--exclude '*~'                            \
	--exclude '#*'                            \
	../$(*F)/*;                               \
	if [ $$linkeddir -ne 0 ]; then            \
		rm -f ../$(__pkgname); fi;              \
	if [ ! -r $@ ]; then echo "$(W_PREFIX) failed to create $@"; exit 1; fi;

else
package:
	@echo "No package (tar) command available";
endif
# ******************************************************************************


# Package/Rpm target
# ******************************************************************************
# Rules for build and creating rpm files. Requires a rpmbuild command to be
# installed on the system. Specfile is removed when doing clean or distclean
.PHONY: __remove_specfile rpm rpmenvironment rpmenvironment.clean

# Clean target for specfile outside the if-def because rpm commands are only
# enabled when an rpm-target is in MAKECMDGOALS.
__rpmspecfile := $(__name).spec
distclean clean: __remove_specfile
__remove_specfile:
	@if [ -e $(__rpmspecfile) ]; then \
		echo "$(T_PREFIX) Removing $(__rpmspecfile) ..."; \
		$(__bob.cmd.rm) $(__rpmspecfile); \
	fi;

ifneq "$(__bob.cmd.rpmbuild)" ""

# Check prerequisites
ifeq "$(__bob.cmd.awk)" ""
$(error Must have gawk)
endif

ifeq "$(__bob.cmd.tar)" ""
$(error Must have tar)
endif

ifeq "$(__bob.cmd.rpm)" ""
$(error Must have rpm)
endif

ifdef META_BUILD_ROOT
RPM_USER_ROOT := $(abspath $(META_BUILD_ROOT)/rpm)
endif

ifndef RPM_USER_ROOT
RPM_USER_ROOT := $(shell $(__bob.cmd.rpm) --eval %_topdir)
endif

# Reset package if we have rpm. Obs do not move this line above the tar package
# definition section.
__pkgdir := $(shell $(__bob.cmd.rpm) --define '_topdir $(RPM_USER_ROOT)' --eval %_sourcedir)

# Target rpm is like package just a bit more complex. Depends on package file,
# but also on some flags being defined. RELEASENAME and RPMFLAGS.
#
# RPM_BUILD_FLAGS is still necessary. It must be possible to send in just any
# type of flag to the rpm-command. Besides, RPMFLAGS is also used for forcing a
# specific value on the _topdir macro in rpm. This feature is hidden behind the
# variable RPM_USER_ROOT which can be set in the environment or on the command
# line in order to redirect the output of rpmbuild to a different directory.
#
# The specfile is created by running spec.in through awk. We modify the release
# if code is from trunk or a branch.
$(__rpmspecfile): awkvars := $(addprefix -v,$(foreach t,name version release group,$t=$(__$t)))
$(__rpmspecfile): $(__rpmspecfile).in $(__rpmmacrofile) __always_build__
	@if [ -e "$<" ]; then \
		echo "$(T_PREFIX) SPECFILE $@ : $(awkvars)"; \
		$(__bob.cmd.awk) $(awkvars) -f $(BOBHOME)/specreplace.awk $< > $@; fi

comma := ,
rpm: $(__pkgdir)/$(__pkgfile)
rpm: override RPM_BUILD_FLAGS := \
	$(foreach d,$(subst $(comma),$(space),$(RPM_BUILD_DEFINES)),--define '$(subst =,$(space),$d)') \
	$(foreach w,$(subst $(comma),$(space),$(RPM_BUILD_WITHS)),--$(subst =,$(space),$w))
rpm: RPM_BUILD_OPTION := -bb
rpm: override RPM_BUILD_FLAGS += $(RPM_BUILD_OPTION)
rpm: override RPM_BUILD_FLAGS += --define '_topdir $(RPM_USER_ROOT)'
rpm: override RPM_BUILD_FLAGS += $(if $(__bob.buildarch),--target=$(__bob.buildarch))
rpm: $(__rpmspecfile) | rpmenvironment
	@+if [ -e "$<" ]; then \
		echo "$(T_PREFIX) RPMFILE : $(RPM_BUILD_FLAGS)"; \
		$(__bob.cmd.rpmbuild) $(RPM_BUILD_FLAGS) $(__rpmspecfile); fi

# RPM build environment in users home and all the directories needed.  Some
# directories must exist for the rpmbuild command to work. Install these.
__rpmdirectories := $(addprefix $(RPM_USER_ROOT)/,BUILD RPMS SOURCES SPECS SRPMS)
$(__rpmdirectories):
	$(INSTALL_DIRS) $@
__rpmmacrofile := $(HOME)/.rpmmacros
$(__rpmmacrofile): $(BOBHOME)/rpmmacros
	$(INSTALL) -T $< $@

# Target for installing macro file and directories.
rpmenvironment: $(__rpmmacrofile) $(__rpmdirectories)

# Clean rpm environment. Mostly for debugging.
rpmenvironment.clean:
	@$(__bob.cmd.rmdir) $(__rpmmacrofile) $(__rpmdirectories)

else
rpm:
	@echo "No rpmbuild command available";
endif
# ******************************************************************************


# Phony target to depend upon if target must always be triggered.
.PHONY: __always_build__
