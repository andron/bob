# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Default mode, i.e. just compile a single bob-project.

# Extract version information by including the makerules.mk with empty header
# and footer to prevent traversing the tree of makerules.mk files.
HEADER :=
FOOTER :=
include $(RULES)
__name     := $(NAME)
__version  := $(VERSION)
__release  := $(RELEASE)
__requires := $(REQUIRES)
# Revert variables back to real files.
HEADER := $(HEADER_BUILD)
FOOTER := $(FOOTER_BUILD)

# Set a variable indicating that we are in build mode.
__bobBUILDSTAGE := 1

# Default targets, which are all double-colon so that each module can add more
# rules to the same target if they need to. Neither clean nor install should
# need any such rules... but who knows.
clean-tgt:
	@-$(RM) -rf $(TGTBASE)
clean-obj:
	@-$(RM) -rf $(OBJBASE)

clean: clean-tgt clean-obj

$(if $(__bobFIND), \
	$(eval FINDRM := $(__bobFIND) . \( -name "*~" -or -name "\#*" \) -print -exec rm -f {} \;),\
	$(eval FINDRM := echo Command \'find\' not available))
distclean:
	@-printf "%-30s %s\n" "$(T_PREFIX)" "$@"; \
	$(RM) -rf $(TGTBASE) $(OBJBASE); \
	$(FINDRM)


# Install targets
install: all

# "Software install"
software-install: __latest := $(__name)-$(__version)
software-install: override prefix := $(software-prefix)/$(__name)/$(__name)-$(__version)
software-install: all
	@-$(MAKE) install prefix=$(prefix); \
	cd $(prefix)/.. && rm -f latest && ln -sf $(__latest) latest


# Doc targets
# Simple doxygen implementation. If doxyfile is present run doxygen.
DOXYGEN_FILE ?= Doxyfile
DOXYGEN_OPTS ?= 
doc:
	@if [ -r $(DOXYGEN_FILE) ]; then \
		doxygen $(DOXYGEN_FILE); \
	else \
		echo "No doxygen input file: $(DOXYGEN_FILE)"; \
		echo "Create a $(DOXYGEN_FILE) using 'doxygen -g'"; \
	fi;
distclean: clean-doc
clean-doc:
	@-$(RM) -rf $(DOCDIR)

ifdef __bob_have_feature_cppcheck
cppcheck:;
endif

# Empty target, just to get the parsing going.
verify:;
	@-printf "%-30s %s\n" "$(T_PREFIX)" "$@"

# Display version for the project.
version:
	@echo $(__name) $(__version)

# Mark all non-file targets as phony.
.PHONY: \
	all doc verify install software-install component-install distclean \
	clean clean-obj clean-tgt .PRE_ALLTARGETS

# The default all target, no rules.
all: $(TGTDIR)

# Functions for building rules, setting up dependencies etc.
# ******************************************************************************
include $(BOBHOME)/Makefile.functions.mk


# Include compiler file.
# ******************************************************************************
include $(BOBHOME)/Makefile.compiler.$(COMPILER).mk


# Include a recipe file
# ******************************************************************************
ifdef recipe
override __bobRECIPE := $(abspath $(recipe))
override __bobRECIPE_ORIGIN := $(origin recipe)
$(if $(wildcard $(__bobRECIPE)),,\
	$(info $(W_PREFIX) Specified recipe does not exist!)\
	$(info $(W_PREFIX)    origin: [$(__bobRECIPE_ORIGIN)])\
	$(info $(W_PREFIX)    file:   $(__bobRECIPE))\
	$(error Missing file error))
override RECIPE_DIR := $(dir $(abspath $(recipe)))
include $(__bobRECIPE)
# Parse the recipe and make *some* magic happen, not to much this time, to not
# confuse user etc.
$(call __bob_setup_recipe)
# This will store the newly included defines (and such stuff). Further calls to
# this function will cause an error if defines have been modified or removed.
$(call __bob_check_defines_flag)
endif


# Turn on second expansion.
# ******************************************************************************
.SECONDEXPANSION:
.ONESHELL:

# Init plugins. Plugins shall not provide base functionally and shall thus be
# inited until after all default files. And since plugins might provide target
# definitions in their init-file they must also be initiated after the
# SECONDEXPANSION directive, BUT before the makerules.mk include starts, else
# they would be in-effective since it is the init-file that enables the plugin.
# ******************************************************************************
ifdef BOBPLUGINS
__bob_plugins := $(addprefix $(__bobPLUGINDIR)/,$(BOBPLUGINS))
override __bobPLUGINSINITS   := $(wildcard $(addsuffix /$(PLUGININIT),$(__bob_plugins)))
override __bobPLUGINSHEADERS := $(wildcard $(addsuffix /$(PLUGINHEAD),$(__bob_plugins)))
override __bobPLUGINSFOOTERS := $(wildcard $(addsuffix /$(PLUGINFOOT),$(__bob_plugins)))
override __bobPLUGINSPOSTS   := $(wildcard $(addsuffix /$(PLUGINPOST),$(__bob_plugins)))
.PHONY: $(__bobPLUGINSINITS) $(__bobPLUGINSHEADERS) $(__bobPLUGINSFOOTERS) $(__bobPLUGINSPOSTS)
MAKEFILE_LIST :=
-include $(__bobPLUGINSINITS)
endif


# Module dependent section, relies heavily on second expansion. The compiler
# options makefile contains rules which much be expanded, which is why it is put
# here, i.e. after the .SECONDEXPANSION row. From here on all makerules.mk files
# specifed by submodules will be read and parsed. All variables specified so far
# are available for usage in the makerules.mk-files.
# ******************************************************************************
$(if $(filter $(disablecheckfor) \
	doc rpmenv buildinfo package distclean clean clean-% \
	cm-% %.spec help% linkgraph% requiregraph%,$(MAKECMDGOALS)),\
	$(eval __bobDISABLECHECKREQUIREMENTS := yes))
$(if $(filter distclean,$(MAKECMDGOALS)),\
	$(eval RULES :=))
MAKEFILE_LIST :=
-include $(RULES)


# Include "global" target specifications.
# ******************************************************************************
include $(BOBHOME)/Makefile.globaltargets.mk

# Helper targets for various stuff.
# ******************************************************************************
include $(BOBHOME)/Makefile.helpertargets.mk


# Post-process, stuff...
# ******************************************************************************
# Setup all target inter-dependencies, i.e. target-to-target deps. This must be
# done post-parsing all module makerules otherwise a dependency might not be
# defined, and ITS deps cannot be expanded.
$(call pp_setup_target_link_dependencies,$(__bobLIST_TARGETS))

# Setup all and export all bin and lib paths
$(call pp_setup_libbin_paths)

# Setup pre and post deps target for doing stuff... of various kind.
.PRE_ALLTARGETS:
$(call pp_setup_prepost_dependency_targets,$(__bobLIST_TARGETS))


# Include all .d-files. This is handled via setup_target.
%.d:;
#MAKEFILE_LIST :=
#-include $(addsuffix .d,$(basename $(__bobLIST_ALLOBJECTS)))


# Help targets, defined elsewhere to stay "non-gloggy". This part is placed
# "down" here bacause the help uses variables defined and assigned within the
# sub-makerules.mk files.
# ******************************************************************************
ifneq "$(filter help%,$(MAKECMDGOALS))" ""
include $(BOBHOME)/Makefile.help.mk
endif


# Do all post processing for plugins.
# ******************************************************************************
ifdef BOBPLUGINS
-include $(__bobPLUGINSPOSTS)
endif


# For debugging.
ifdef __bobPARSEONLY
$(error Done)
endif
