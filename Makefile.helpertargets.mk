# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, Saab AB
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
#
# $(1): Module name
# ------------------------------------------------------------------------------
.PHONY: bobshell buildshellinfo
buildshellinfo:
	@echo
	@printf " %-12s %s\n" "Project:"  "$(__name)-$(__version)-$(__release)"
	@printf " %-12s %s\n" "Requires:" "$(sort $(REQUIRES))"
	@printf " %-12s %s\n" "DEFINES:"  "$(strip $(DEFINES)")
	@printf " %-12s %s\n" "CXXFLAGS:" "$(strip $(CXXFLAGS))"
	@printf " %-12s %s\n" "CFLAGS:"   "$(strip $(CFLAGS))"
	@printf " %-12s %s\n" "LDFLAGS:"  "$(strip $(LDFLAGS))"
bobshell: BOBSHELL_RESTRICTED ?=
bobshell:
	@if [ $$BOBBUILDBASH ]; then \
		echo $$SHLVL; \
		echo ; \
		echo "Ups, you must run 'make $@' from a level 1 shell. (SHLVL > 1)"; \
		echo "In this case you are running a $@ within a $@."; \
		echo ; \
		exit 0; \
	else \
		LD_LIBRARY_PATH=$(abspath $(TGTDIR)):$$LD_LIBRARY_PATH:$${__bobLISTHOMELIBS// /:}; \
		PATH=$$PATH:$(abspath $(TGTDIR)):$${__bobLISTHOMEBINS// /:}; \
		export LD_LIBRARY_PATH=$${LD_LIBRARY_PATH//::/:}; \
		export PATH=$${PATH//::/:}; \
		export TEST_INCLUDES="$(__bobLISTHOMEINCL)"; \
		export BOBBUILDBASH=1; \
		export RECIPEFILE=$(recipe); \
		export MAKELEVEL=0; \
		bash --noprofile --rcfile $(BOBHOME)/bobbashrc $(BOBSHELL_RESTRICTED); \
		echo " ... done with recipe $(recipe)"; \
	fi;
# ------------------------------------------------------------------------


# Tar file generating target.
# ******************************************************************************
# Generic rule for making a tar.gz file. Uses package destdir as base for all
# its operations. Which must be specified by the dependee target. I.e. the
# target that depends on a tar.gz file must define the variable.  (It is very
# unusual that a developer would need to use this directly).
ifdef __bob_have_feature_tar

.PHONY: package __remove_packagefile

__pkgdir  := $(HOME)/bobpackages
__pkgname := $(__name)-$(__version)
__pkgfile := $(__pkgname).tar.gz

distclean clean: __remove_packagefile
__remove_packagefile:
	@if [ -e $(__pkgdir)/$(__pkgfile) ]; then \
		echo "$(T_PREFIX) Removing package file ..."; \
		$(RM) $(__pkgdir)/$(__pkgfile); \
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
	$(__bobTAR) $(__pkgflags) $@              \
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

endif
# ******************************************************************************


# Package/Rpm target
# ******************************************************************************
# Rules for build and creating rpm files. Requires a rpmbuild command to be
# installed on the system.
ifdef __bob_have_feature_rpm

# Check prerequisites
ifeq "$(__bobAWK)" ""
$(error Must have gawk)
endif

ifeq "$(__bobTAR)" ""
$(error Must have tar)
endif

ifndef RPM_USER_ROOT
RPM_USER_ROOT := $(shell rpm --eval %_topdir)
endif

# The rpm specfile shall have the same name as the project.
__rpmspecfile := $(__name).spec

# Reset package if we have rpm. Obs do not move this line above the tar package
# definition section.
__pkgdir := $(shell rpm --define '_topdir $(RPM_USER_ROOT)' --eval %_sourcedir)

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
$(__rpmspecfile): $(__rpmspecfile).in __always_build__
	@if [ -e "$<" ]; then \
		echo "$(T_PREFIX) SPECFILE $@ : $(awkvars)"; \
		$(__bobAWK) $(awkvars) -f $(BOBHOME)/specreplace.awk $< > $@; fi

# Remove the specfile when doing clean or distclean
distclean clean: __remove_specfile
__remove_specfile:
	@$(RM) $(__rpmspecfile)

comma := ,
rpm: $(__pkgdir)/$(__pkgfile)
rpm: override RPM_BUILD_FLAGS := \
	$(foreach d,$(subst $(comma),$(space),$(RPM_BUILD_DEFINES)),--define '$(subst =,$(space),$d)') \
	$(foreach w,$(subst $(comma),$(space),$(RPM_BUILD_WITHS)),--$(subst =,$(space),$w))
rpm: RPM_BUILD_OPTION := -bb
rpm: override RPM_BUILD_FLAGS += $(RPM_BUILD_OPTION)
rpm: override RPM_BUILD_FLAGS += --define '_topdir $(RPM_USER_ROOT)'
rpm: $(__rpmspecfile) | rpmenvironment
	@+if [ -e "$<" ]; then \
		echo "$(T_PREFIX) RPMFILE : $(RPM_BUILD_FLAGS)"; \
		$(__bobRPMBUILD) $(RPM_BUILD_FLAGS) $(__rpmspecfile); fi

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
	@$(RM) -rf $(__rpmmacrofile) $(__rpmdirectories)

.PHONY: __remove_specfile rpm rpmenvironment rpmenvironment.clean

endif
# ******************************************************************************


# Phony target to depend upon if target must always be triggered.
.PHONY: __always_build__
