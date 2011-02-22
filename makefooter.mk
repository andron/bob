# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Sort and strip to avoid duplicates, spaces and tabs.
TARGETS			:= $(strip $(sort $(TARGETS)))
SUBMODULES	:= $(strip $(sort $(SUBMODULES) test))

# Prevent archive targets
$(if $(filter lib%.a,$(TARGETS)),\
	$(eval TARGETS := $(filter-out lib%.a,$(TARGETS)))\
	$(info $(W_PREFIX) Archives are deprecated, update $(_MODULE)/$(RULES)))

# Copy target to all targets list so that different processing can be done
# depending on plugins and such stuff. Operations which should be untouched by
# plugins should use ALL_TARGETS.
ALL_TARGETS := $(TARGETS)

# Save all targets to a list for later dependency processing.
__bobLIST_TARGETS := $(__bobLIST_TARGETS) $(ALL_TARGETS)

# Save all modules
__bobLIST_MODULES := $(__bobLIST_MODULES) $(_MODULE)

# Store requirements, but only allow for one round of assignment.
ifndef __requirements_is_set__
__bobLIST_REQUIRES := $(__bobLIST_REQUIRES) $(REQUIRES)
override __requirements_is_set__ := yes
endif


# Call plugin footers.
ifdef BOBPLUGINS
-include $(__bobPLUGINSFOOTERS)
endif


# Save variables in module specific ones.
$(_MODULE)_INSTALL_HEADERS := $(INSTALL_HEADERS)
$(_MODULE)_INSTALL_SBIN    := $(INSTALL_SBIN)
$(_MODULE)_TARGETS         := $(addprefix $(TGTDIR)/,$(TARGETS))


# Check if variable DEFINES has been altered.
$(call __bob_check_defines_flag)


# Append module defines to each target defines.
$(if $(_DEFINES),$(foreach t,$(ALL_TARGETS),$(eval $t_DEFINES += $(_DEFINES))))


# Set a default ui-style depending on requirements.
ifeq "$(UI_STYLE)" ""
$(if $(findstring qt4,$(__bobLIST_REQUIRES)),\
	$(eval UI_STYLE := qt4),\
	$(if $(findstring qt,$(__bobLIST_REQUIRES)),\
		$(eval UI_STYLE := qt3),\
		$(eval UI_STYLE := qt4)))
endif

# Call a lot of macros to check, hmm... "stuff"
#
# @note: The <T>_LIBS variable is parsed to figure out which libraries are
#        linked against, i.e. it needs special treatment.
#
$(foreach t,$(ALL_TARGETS),																				\
	$(eval $t_LIBS += $(_LIBS))																			\
	$(call __bob_append_src_objects,$t,$($(_MODULE)_OBJDIR))				\
	$(call __bob_append_uic_objects,$t,$($(_MODULE)_OBJDIR))				\
	$(call __bob_append_moc_objects,$t,$($(_MODULE)_OBJDIR))				\
	$(call setup_uic_depend_rules,$t,$($(_MODULE)_OBJDIR))					\
	$(call setup_uic_depend_rules_srcs,$t,$($(_MODULE)_OBJDIR))			\
	$(eval $(call setup_target,$t,$(_MODULE))))

# Setup form (moc) rules for all targets. This macro takes all targets into
# consideration and skips duplicate files.
$(eval $(call setup_forms_rules_$(UI_STYLE),$(strip $(ALL_TARGETS)),$(_MODULE)))

# Setup cppcheck targets.
ifdef __bob_have_feature_cppcheck
$(eval $(call setup_cppcheck,$(strip $(ALL_TARGETS)),$(_MODULE)))
endif

# The variable can be reset here, to force qt3 components to explicitly set
# their style. This should be removed as soon as possible.
#UI_STYLE :=

# Module rules
# ----------------------------------------------------------------------------
# The stamp file is precious, and the module name itself should be phony. A
# problem with having the module as a phony target is that a target in the
# module with the same name as the module will then also be phony... (later)
.PRECIOUS: \
	$($(_MODULE)_OBJDIR).stamp														\
	$($(_MODULE)_OBJDIR)%.o																\
	$($(_MODULE)_OBJDIR)%$(__moc-cpp)											\
	$($(_MODULE)_OBJDIR)%$(subst .cpp,.o,$(__moc-cpp))		\
	$($(_MODULE)_OBJDIR)%.moc.o														\
	$($(_MODULE)_OBJDIR)%$(__ui-h)												\
	$($(_MODULE)_OBJDIR)%$(__ui-cpp)											\
	$($(_MODULE)_OBJDIR)%$(__ui-moc-cpp)									\
	$($(_MODULE)_OBJDIR)%$(subst .cpp,.o,$(__ui-cpp)) 		\
	$($(_MODULE)_OBJDIR)%$(subst .cpp,.o,$(__ui-moc-cpp))

# Phony target in module.
.PHONY: \
	__module-$(_MODULE) \
	__module-install-$(_MODULE) \
	__module-install-test-$(_MODULE)

# Connect the module to the all: target and then connect the module targets and
# submodules to the module itself.
all: __module-$(_MODULE)
__module-$(_MODULE): $($(_MODULE)_TARGETS)

# This causes circular deps, but can be used for lazy-make-command-users.
#__module-$(_MODULE): $(addprefix __module-,$(wildcard $(filter-out test,$(SUBMODULES))))

# Separate clean targets for each module.
$(eval $(call generate_clean_targets,$(_MODULE)))

# Install target will only be added for REAL targets not TEST targets. The
# module's install target will be connected to the global install:
# target. Libraries and binaries will be installed. Extra stuff like docs and
# misc files must be added manually by the module owner.
install: __module-install-$(_MODULE)
install-test: __module-install-test-$(_MODULE)

# Put different targets into different directories. There is no way of knowing
# whether foo should go into bindir or sbindir for example. All targets are
# installed even test targets.
$(eval $(call generate_install_targets,$(_MODULE),$(ALL_TARGETS)))

# Include submodules. This must be done here, last in the footer file, to not
# mess up the ongoing header-content-footer section. The submodule names are
# prepended with the current modules directory to become fully "pathed".
$(eval $(call __bob_include_submodules,$(_MODULE),$(SUBMODULES)))
