# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Meta build differs from ordinary build, clean, distclean targets etc.

# Find all sub-project makerules files.
__subprojectrules := $(wildcard $(addsuffix /$(RULES),$(wildcard *)))
# Find all sub-project info files, which contains build info.
__subprojectinfos := $(wildcard $(addsuffix /$(INFOS),$(wildcard *)))
# Filter out sub-projects from the makerules.mk list if they have an info file.
__subprojectrules := \
	$(filter-out $(subst $(INFOS),$(RULES),$(__subprojectinfos)),$(__subprojectrules))


# Use different prefix in meta mode.
__bobPREFIX := " [bob]"


# Default prefix for installation of everything.
META_BUILD_ROOT := $(builddir)/bobuild/$(PLATFORM)
export prefix := $(abspath $(META_BUILD_ROOT)/install)


# Turn on second expansion.
.SECONDEXPANSION:
.ONESHELL:


# Only enable some plugins in meta builds.
BOBPLUGINS := dotgraph
ifdef BOBPLUGINS
BOBPLUGINS := $(addprefix $(__bobPLUGINDIR)/,$(BOBPLUGINS))
-include $(wildcard $(addsuffix /$(__bobPLUGININIT),$(BOBPLUGINS)))
endif


# Define a set of main targets which are supported at the top level.
PASS_TARGETS := \
	clean clean-tgt clean-obj distclean \
	doc verify linkgraph versioninfo \
	test   test.reg  test.tdd  test.mod  test.tmp \
	check check.reg check.tdd check.mod check.tmp


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
	echo "$(__bobPREFIX) Removing temporary install directory $${foo##$(PWD)\/}"; \
	$(RM) -rf $(META_BUILD_ROOT)

help:
	@echo "$(__bobPREFIX) Help not available in meta mode, yet"

# Include all sub-project files, using a info header for the parsing. Instead of
# the normal build headers used by the build-stage.

HEADER := $(HEADER_INFO)
FOOTER := $(FOOTER_INFO)
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
	@+$(MAKE) --no-print-directory -C $($*_DIRECTORY)

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


#
# !!!Do the api-to-api sanity matching!!! Rewrite, not in use, untested.
#
# ******************************************************************************
# For every project/subproject/submodule whatever go through every requirement
# and extract the available level and the accepted level. Filtering out the
# accepted level from available level should result in a empty string. If the
# string is not empty emit an a warning en set missmatching_apilevel to yes for
# later checking.  If successfull, then create a rule which connect the build
# part to the install part of the requirement. This connection cannot be done in
# the footer since we do not know all available projects at that time and can
# thus not do any checking whether or not the required interface is available.
#
# Here build, install etc are connected to the respective required interface
# install target. !!!This is a crucial part, this connects projects to each
# other. It is the last eval in the code block below!!!
#
# The first if-clause prevents deps to be setup against projects which are not
# buildable. E.g. Qt, Xerces and other external software.
#
$(foreach n,$(LIST_NAMES),\
$(foreach r,$($n_REQUIRES),\
	$(eval r_n                := $(call __get_name,$r))\
	$(eval r_nv               := $(call __get_VAR,$r,_VERSION))\
	$(eval accepted           := $(call __get_gt_feature,$r,$(r_nv)))\
	$(eval available          := $(call __get_feature,$(r_nv)))\
	$(eval available_featname := $(call __get_compactFname,$(r_nv)))\
	$(if $(findstring $(r_n),$(LIST_NAMES)),\
		$(if $(filter-out $(accepted),$(available)),\
			$(eval missmatching_apilevel := yes)\
			$(info $(W_PREFIX) INTERFACE ERROR: $n -> $r != $(r_nv)),\
			$(eval $(addsuffix $($n_FEATNAME),build_ rpm_ install_): install_$(available_featname))))))

# Diplay error, and abort.
$(if $(missmatching_apilevel),\
	$(info $(W_PREFIX) ********************************************************************)\
	$(info $(W_PREFIX) There are missmatching interfaces between software in this setup.)\
	$(info $(W_PREFIX) This will/should never compile, and therefore the build is aborted.)\
	$(info $(W_PREFIX) See the above warnings for information about conflicting software.)\
	$(info $(W_PREFIX) (If you are of another opinion, get your interfaces right!))\
	$(info $(W_PREFIX) ********************************************************************)\
	$(error Miss-matching interfaces error))
# ******************************************************************************


# Do all post processing for plugins
# ******************************************************************************
ifdef BOBPLUGINS
-include $(wildcard $(addsuffix /$(__bobPLUGINPOST),$(BOBPLUGINS)))
endif
