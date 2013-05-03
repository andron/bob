# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Default mode, i.e. just compile a single bob-project.


# Directory configuration
# ******************************************************************************
TGTBASE := $(abspath $(builddir)/tgt)
OBJBASE := $(abspath $(builddir)/obj)
DOCBASE := $(abspath $(builddir)/doc)
export TGTDIR := $(TGTBASE)/$(PLATFORM)/$(__bob.buildtype)_$(__bob.compiler)
export OBJDIR := $(OBJBASE)/$(PLATFORM)/$(__bob.buildtype)_$(__bob.compiler)
export DOCDIR := $(DOCBASE)/generated
# ******************************************************************************


# Extract version information by including the makerules.mk with empty header
# and footer to prevent traversing the tree of makerules.mk files.
HEADER :=
FOOTER :=
include $(__bob.file.rules)
__name     := $(NAME)
__version  := $(VERSION)
__release  := $(RELEASE)
__group    := Other
__requires := $(REQUIRES)
# Revert variables back to real files.
HEADER := $(__bob.file.headerb)
FOOTER := $(__bob.file.footerb)

__bobBUILDSTAGE := 1

# Default targets, which are all double-colon so that each module can add more
# rules to the same target if they need to. Neither clean nor install should
# need any such rules... but who knows.
clean-tgt:
	@-$(__bob.cmd.rmdir) $(TGTBASE)
clean-obj:
	@-$(__bob.cmd.rmdir) $(OBJBASE)

clean: clean-tgt clean-obj

$(if $(__bob.cmd.find), \
	$(eval FINDRM := $(__bob.cmd.find) . \( -name "*~" -or -name "\#*" \) -print -exec $(__bob.cmd.rm) {} \;),\
	$(eval FINDRM := echo Command \'find\' not available))
distclean:
	@-printf "%-30s %s\n" "$(T_PREFIX)" "$@"; \
	$(__bob.cmd.rmdir) $(TGTBASE) $(OBJBASE); \
	$(FINDRM)


# Install targets
install: all


# "Software install"
software-install: __latest := $(__name)-$(__version)
software-install: override prefix := $(software-prefix)/$(__name)/$(__name)-$(__version)
software-install: all
	@-$(MAKE) install prefix=$(prefix); \
	cd $(prefix)/.. && $(__bob.cmd.rm) latest && $(__bob.cmd.ln) $(__latest) latest


# Doc targets
# Simple doxygen implementation. If doxyfile is present run doxygen.
ifdef __bob_have_feature_doxygen
DOXYGEN_FILE ?= Doxyfile
DOXYGEN_OPTS ?= 
doc:
	@if [ -r $(DOXYGEN_FILE) ]; then \
		$(__bob.cmd.doxygen) $(DOXYGEN_FILE); \
	else \
		echo "No doxygen input file: $(DOXYGEN_FILE)"; \
		echo "Create a $(DOXYGEN_FILE) using 'doxygen -g'"; \
	fi;
else
doc:;
endif
distclean: clean-doc
clean-doc:
	@-$(__bob.cmd.rmdir) $(DOCDIR)

ifdef __bob_have_feature_cppcheck
cppcheck:;
endif

# Empty target, just to get the parsing going.
verify:;
	@-printf "%-30s %s\n" "$(T_PREFIX)" "$@"

# Mark all non-file targets as phony.
.PHONY: \
	all doc verify install software-install distclean \
	clean clean-obj clean-tgt

# The default all target, no rules.
all: | $(TGTDIR)


# Functions for building rules, setting up dependencies etc.
# ******************************************************************************
.PHONY: $(BOBHOME)/Makefile.functions.mk
include $(BOBHOME)/Makefile.functions.mk


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
__bob_plugins := $(addprefix $(__bob.plugin.dir)/,$(BOBPLUGINS))
override __bob.plugin.inits   := $(wildcard $(addsuffix /$(__bob.plugin.init),$(__bob_plugins)))
override __bob.plugin.headers := $(wildcard $(addsuffix /$(__bob.plugin.head),$(__bob_plugins)))
override __bob.plugin.footers := $(wildcard $(addsuffix /$(__bob.plugin.foot),$(__bob_plugins)))
override __bob.plugin.posts   := $(wildcard $(addsuffix /$(__bob.plugin.post),$(__bob_plugins)))
.PHONY: $(__bob.plugin.inits) $(__bob.plugin.headers) $(__bob.plugin.footers) $(__bob.plugin.posts)
MAKEFILE_LIST :=
-include $(__bob.plugin.inits)
endif


# Module dependent section, relies heavily on second expansion. The compiler
# options makefile contains rules which much be expanded, which is why it is put
# here, i.e. after the .SECONDEXPANSION row. From here on all makerules.mk files
# specifed by submodules will be read and parsed. All variables specified so far
# are available for usage in the makerules.mk-files.
# ******************************************************************************
$(if $(filter $(disablecheckfor) \
	doc rpmenvironment rpmenvironment.% buildinfo package distclean clean clean-% \
	%.spec help% linkgraph% requiregraph%,$(MAKECMDGOALS)),\
	$(eval __bobDISABLECHECKREQUIREMENTS := yes))
# If distclean is requested disable further inclusion of makerules files.
$(if $(filter distclean,$(MAKECMDGOALS)),\
	$(eval __bob.file.rules :=))


# Include the first rules file, this is where the parsing begins.
# ******************************************************************************
MAKEFILE_LIST :=
-include $(__bob.file.rules)


# Include "global" target specifications. This file mostly includes targets
# for compiling and linking, but also some target for creating directories and
# other temporary artifacts.
# ******************************************************************************
.PHONY: $(BOBHOME)/Makefile.globaltargets.mk
include $(BOBHOME)/Makefile.globaltargets.mk


# Helper targets for various stuff.
# ******************************************************************************
.PHONY: $(BOBHOME)/Makefile.helpertargets.mk
include $(BOBHOME)/Makefile.helpertargets.mk


# Post-process, stuff...
# ******************************************************************************
# Setup all target inter-dependencies, i.e. target-to-target deps. This must be
# done post-parsing all module makerules otherwise a dependency might not be
# defined, and ITS deps cannot be expanded.
$(call pp_setup_target_link_dependencies,$(__bobLIST_TARGETS))

# Setup all and export all bin and lib paths
$(call pp_setup_libbin_paths)


# Empty target for .d-files. Including is handled via setup_target macro.
%.d:;


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
MAKEFILE_LIST :=
-include $(__bob.plugin.posts)
endif
