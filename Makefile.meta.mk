# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Meta build differs from ordinary build, clean, distclean targets etc.

# Find all sub-project makerules files.
__subprojectrules := $(wildcard $(addsuffix /$(__bob.file.rules),$(wildcard *)))
# Find all sub-project info files, which contains build info.
__subprojectinfos := $(wildcard $(addsuffix /$(__bob.file.infos),$(wildcard *)))
# Filter out sub-projects from the makerules.mk list if they have an info file.
__subprojectrules := \
	$(filter-out $(subst $(__bob.file.infos),$(__bob.file.rules),$(__subprojectinfos)),$(__subprojectrules))


# Use different prefix in meta mode.
__bob.prefix := " [bob]"


# Default prefix for installation of everything.
META_BUILD_ROOT := $(builddir)/bobuild/$(PLATFORM)
export prefix := $(abspath $(META_BUILD_ROOT)/install)


# Turn on second expansion.
.SECONDEXPANSION:
.ONESHELL:


# Only enable some plugins in meta builds.
BOBPLUGINS := dotgraph
ifdef BOBPLUGINS
BOBPLUGINS := $(addprefix $(__bob.plugin.dir)/,$(BOBPLUGINS))
-include $(wildcard $(addsuffix /$(__bob.plugin.init),$(BOBPLUGINS)))
endif


# Define a set of main targets which are supported at the top level.
PASS_TARGETS := \
	clean clean-tgt clean-obj distclean \
	doc verify linkgraph versioninfo \
	test   test.reg  test.tdd  test.bdd  test.mod  test.tmp \
	check check.reg check.tdd check.bdd check.mod check.tmp


# Have cppcheck or not.
ifdef __bob_have_feature_cppcheck
PASS_TARGETS += cppcheck
endif


# All main targets for a meta build.
MAIN_TARGETS := all install software-install $(PASS_TARGETS)


# Have rpm or not.
ifdef __bob_have_feature_rpm
export RPM_USER_ROOT := $(abspath $(META_BUILD_ROOT)/rpm)
MAIN_TARGETS += rpm
endif


# Make these phony targets so that Make won't look for files names like this.
.PHONY: $(MAIN_TARGETS) __remove_meta_install_dir

# When the meta level is done, say something.
$(MAIN_TARGETS):
	@echo -e "\n" \
		"**************************************************\n"\
		" Meta stage $@, completed successfully\n"\
		" $$(date)\n"\
		"**************************************************\n"


# This can become quite parallell, so we use low resolution as a precaution.
.LOW_RESOLUTION_TIME: $(MAIN_TARGETS)


distclean: __remove_meta_install_dir
__remove_meta_install_dir:
	@-foo=$(META_BUILD_ROOT); \
	echo "$(__bob.prefix) Removing temporary install directory $${foo##$(PWD)\/}"; \
	$(__bob.cmd.rmdir) $(META_BUILD_ROOT)

help:
	@echo "$(__bob.prefix) Help not available in meta mode, yet"

# Include all sub-project files, using a info header for the parsing. Instead of
# the normal build headers used by the build-stage.

HEADER := $(__bob.file.headeri)
FOOTER := $(__bob.file.footeri)
include $(__subprojectinfos)
include $(__subprojectrules)


# The list of targets which just gets forwarded without the projects
# version. I.e. target all depends on target all_<P>, where <P> is a project
# name.
$(MAIN_TARGETS): $$(addprefix $$@_,$(LIST_FEATNAMES))

# Target all depends on target build which is the actual build target. Test and
# check are the rest of the dependency chain.
$(addprefix all_,$(LIST_FEATNAMES)):   all_%:   build_%
$(addprefix test_,$(LIST_FEATNAMES)):  test_%:  all_%
$(addprefix check_,$(LIST_FEATNAMES)): check_%: test_%

# Building something is to use a submake (make -C) but no target.
$(addprefix build_,$(LIST_FEATNAMES)): build_%:
	+$(MAKE) -C $($*_DIRECTORY)

# Installing: Submake with target install. Installing one self implies first
# building one self. This must be so to prevent build and install to become two
# different dependecy trees when running in parallell.
$(addprefix install_,$(LIST_FEATNAMES)): install_%: build_%
	@+$(MAKE) --no-print-directory -C $($*_DIRECTORY) install prefix=$($*_PREFIX)

# The software install depends on the normal install.
$(addprefix software-install_,$(LIST_FEATNAMES)): software-install_%: install
	@+$(MAKE) --no-print-directory -C $($*_DIRECTORY) software-install

# Rpm(ing): Submake with target rpm.
ifdef __bob_have_feature_rpm
$(addprefix rpm_,$(LIST_FEATNAMES)): rpm_%: build_%
	@+$(MAKE) -C $($*_DIRECTORY) rpm
endif

# A pass through target is a target that is "passed through". This is just a
# conveniance for reducing repeted code. Build, install etc are special cases
# though. They might need special treatment in the future. Therefore they are
# handled separately.
define pass_through_targets
$(addprefix $1_,$(LIST_FEATNAMES)): $1_%:
	@+$(MAKE) --no-print-directory -C $$($$*_DIRECTORY) $1 prefix=$($*_PREFIX)
endef
$(foreach t,$(PASS_TARGETS),\
	$(eval $(call pass_through_targets,$t)))


# REQUIREMENT DEPENDENCY CHECKING
# ******************************************************************************
# For every project/subproject/submodule whatever go through every requirement
# and extract the available level and connect that requirements install stage
# if the requirement is buildable to the build rpm and install target of the
# requiree.  The if findstring-clause prevents dependencies to be setup
# against projects which are not buildable. E.g. Qt, Boost etc.
$(foreach n,$(LIST_NAMES),\
	$(foreach r,$($n_REQUIRES),\
		$(eval r_n                := $(call __get_name,$r))\
		$(eval r_nv               := $(call __get_available_name_version,$r))\
		$(eval available_featname := $(call __get_compactFname,$(r_nv)))\
		$(if $(findstring $(r_n),$(LIST_NAMES)),\
			$(eval $(addsuffix $($n_FEATNAME),build_ rpm_ install_): install_$(available_featname)))))
# ******************************************************************************


# Do all post processing for plugins
# ******************************************************************************
ifdef BOBPLUGINS
-include $(wildcard $(addsuffix /$(__bob.plugin.post),$(BOBPLUGINS)))
endif
