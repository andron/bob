# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Sort and strip to avoid duplicates, spaces and tabs.
TARGETS    := $(strip $(sort $(TARGETS)))
SUBMODULES := $(strip $(sort $(SUBMODULES) test))

# Ensure the build flags, which are prepended and can thus only be used for
# controling generic aspects of the build, are not duplicated etc
# etc... Multiple += may lead to several -pendantic's etc.
CFLAGS   := $(strip $(sort $(CFLAGS)))
CXXFLAGS := $(strip $(sort $(CXXFLAGS)))
LDFLAGS  := $(strip $(sort $(LDFLAGS)))

# Skip all this stuff if there are not targets. Some might create makerules
# files of this kind to tie directories together.
# TARGETS ----------------------------------------------------------------------
ifneq "$(TARGETS)" ""

# Prevent archive targets
$(if $(filter lib%.a,$(TARGETS)),\
	$(eval TARGETS := $(filter-out lib%.a,$(TARGETS)))\
	$(info $(W_PREFIX) Archives are created automatically, update $(_MODULE)/$(__bob.file.rules)))

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
-include $(__bob.plugin.footers)
endif


# Filter out test.* targets from the TARGETS list.
TEST_TARGETS := $(filter test.%,$(TARGETS))
TARGETS := $(filter-out $(TEST_TARGETS),$(TARGETS))


# Save module's targets and test targets, with full path.
$(_MODULE)_TARGETS      := $(addprefix $(TGTDIR)/,$(TARGETS))
$(_MODULE)_TEST_TARGETS := $(addprefix $(TGTDIR)/,$(TEST_TARGETS))


# If there are test targets, setup variable for test-script, attach targets to
# the different test-classes based on their name. The __execute-target is a
# special construct to execute the test after it has been compiled and linked.
$(if $(TEST_TARGETS),\
	$(foreach t,$(TEST_TARGETS),\
		$(eval $t_SCRIPT_SETUP := $(_SRCDIR)$($t_SCRIPT_SETUP)) \
		$(eval $t_SRCDIR       := $(_SRCDIR))) \
	$(foreach c,$(__bob_test_classes),\
		$(eval test.$c: $(addprefix $(TGTDIR)/,$(filter test.$c.%,$(TEST_TARGETS)))) \
		$(eval check.$c: $(patsubst test.%,__execute.%,$(filter test.$c.%,$(TEST_TARGETS))))) \
	$(eval test: __module-test-$(_MODULE_FULLNAME)) \
	$(eval __module-test-$(_MODULE_FULLNAME): $($(_MODULE)_TEST_TARGETS)))


# Append module defines to each target defines.
$(if $(_DEFINES),$(foreach t,$(ALL_TARGETS),$(eval $t_DEFINES += $(_DEFINES))))


# Implicit x_SRCS if only one target and no SRCS.
ifeq "$(words $(ALL_TARGETS))" "1"
$(eval t := $(firstword $(ALL_TARGETS))) \
$(if $($t_SRCS),,$(eval $t_SRCS := src/*.cpp src/*.c))
endif

# Default ui-style unless specified.
ifeq "$(UI_STYLE)" ""
$(eval UI_STYLE := qt4)
endif

# Call a lot of macros to check, hmm... "stuff"
$(foreach t,$(ALL_TARGETS),                                   \
	$(eval $t_INCL += $(_INCL))                                 \
	$(eval $t_LIBS += $(_LIBS))                                 \
	$(eval $t_USES += $(_USES))                                 \
	$(eval $t_LINK += $(_LINK))                                 \
	$(call __bob_expand_src_wildcard,$t,$($(_MODULE)_SRCDIR),SRCS)     \
	$(call __bob_expand_src_wildcard,$t,$($(_MODULE)_SRCDIR),SRCS_MOC) \
	$(call __bob_expand_src_wildcard,$t,$($(_MODULE)_SRCDIR),SRCS_FRM) \
	$(call __bob_append_src_objects,$t,$($(_MODULE)_OBJDIR))    \
	$(call __bob_append_uic_objects,$t,$($(_MODULE)_OBJDIR))    \
	$(call __bob_append_moc_objects,$t,$($(_MODULE)_OBJDIR))    \
	$(call __bob_append_rcc_objects,$t,$($(_MODULE)_OBJDIR))    \
	$(call setup_uic_depend_rules,$t,$($(_MODULE)_OBJDIR))      \
	$(call setup_uic_depend_rules_srcs,$t,$($(_MODULE)_OBJDIR)) \
	$(call setup_rcc_depend_rules,$t,$($(_MODULE)_OBJDIR))      \
	$(eval $(call setup_target,$t,$(_MODULE))))

# Setup form (moc) rules for all targets. This macro takes all targets into
# consideration and skips duplicate files.
$(eval $(call setup_forms_rules_$(UI_STYLE),$(strip $(ALL_TARGETS)),$(_MODULE)))
$(eval $(call setup_resource_rules_$(UI_STYLE),$(strip $(ALL_TARGETS)),$(_MODULE)))

# Setup cppcheck targets.
ifdef __bob_have_feature_cppcheck
$(eval $(call setup_cppcheck,$(strip $(ALL_TARGETS)),$(_MODULE)))
endif

# Reset ui-style here to force qt3 code to explicitly set their style.
$(eval UI_STYLE :=)

# Module rules
# ******************************************************************************
# The stamp file is precious, and the module name itself should be phony. A
# problem with having the module as a phony target is that a target in the
# module with the same name as the module will then also be phony... (later)
.PRECIOUS: \
	$($(_MODULE)_OBJDIR).stamp                            \
	$($(_MODULE)_OBJDIR)%.o                               \
	$($(_MODULE)_OBJDIR)%$(__moc-cpp)                     \
	$($(_MODULE)_OBJDIR)%$(subst .cpp,.o,$(__moc-cpp))    \
	$($(_MODULE)_OBJDIR)%.moc.o                           \
	$($(_MODULE)_OBJDIR)%$(__res-cpp)                     \
	$($(_MODULE)_OBJDIR)%$(subst .cpp,.o,$(__res-cpp))    \
	$($(_MODULE)_OBJDIR)%$(__ui-h)                        \
	$($(_MODULE)_OBJDIR)%$(__ui-cpp)                      \
	$($(_MODULE)_OBJDIR)%$(__ui-moc-cpp)                  \
	$($(_MODULE)_OBJDIR)%$(subst .cpp,.o,$(__ui-cpp))     \
	$($(_MODULE)_OBJDIR)%$(subst .cpp,.o,$(__ui-moc-cpp))

# TARGETS ----------------------------------------------------------------------
endif

# Phony target in module.
.PHONY: \
	__module-$(_MODULE) \
	__module-install-$(_MODULE) \
	__module-install-test-$(_MODULE)

# Connect the module to the all: target and then connect the module targets and
# submodules to the module itself.
all: __module-$(_MODULE)
__module-$(_MODULE): $($(_MODULE)_TARGETS)

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

ifdef BOB.VERBOSE
$(info $(__bob.prefix) @@ Processing $($(_MODULE)_SRCDIR) ...)
else
ifndef __bobSTARTEDPARSING
__bobSTARTEDPARSING := true
ifeq "$(MAKECMDGOALS)" ""
$(info $(__bob.prefix) @@ Processing buildfiles)
endif
endif
endif
