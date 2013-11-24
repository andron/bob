# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


#
# - Do no edit this file! You will most definitely break something.
# - No I won't...
# - Yes you will...
# - No!
# - Ok, suite your self.
#

# Helper macros
# ******************************************************************************
# Append a directory name $1 before each name in $2, and make sure no double
# slashes exist in the resulting paths.
#
# $1: Directory name -- $2: Name list to be prepended
define __bob_dirprefix
$(if $1,$(addprefix $1/,$2),$(addprefix ./,$2))
endef

# Target .d-files
#
# $1: Target name -- $2: Target object directory
define __bob_target_dfiles
$(eval __objdir := $(addprefix $(OBJDIR)/,$(sort $(dir $($1_SRCS))))) \
$(wildcard $(addsuffix *.d,$(__objdir))) \
$(if $($1_SRCS_RCC),$(wildcard $(addsuffix *.d,$2)))
endef
# ******************************************************************************


# Filters for creating object files from various source files and then a program
# for appending them to the current targets object list.
#
# "Source"-files, moc-files and ui-files are handled.
# 
# foo_objects: $1: Module name
# foo_append_object $1: Module name -- $2: Directory name
# ******************************************************************************
define __bob_src_objects
$(addsuffix .o,$(basename $(filter %.c %.cc %.cpp,$($1_SRCS))))
endef

__ui-h_qt3         := %.h
__ui-h_qt4         := ui_%.h
__ui-cpp           := _ui.cpp
__ui-moc-cpp       := _ui.moc.cpp
__moc-cpp          := .moc.cpp
__res-cpp          := .res.cpp
__srcs_mocs_filter := %.h %.hh %.hpp %.qhh


define __bob_to_uic_header
$(patsubst %.ui,$(__ui-h_$(UI_STYLE)),$1)
endef

define __bob_to_uic_source
$(subst .ui,$(__ui-cpp),$1)
endef

define __bob_to_uic_moc_source
$(subst .ui,$(__ui-moc-cpp),$1)
endef

define __bob_uic_headers
$(notdir $(call __bob_to_uic_header,$($1_SRCS_FRM)))
endef

define __bob_uic_sources_qt3
$(call __bob_to_uic_source,$($1_SRCS_FRM)) $(call __bob_to_uic_moc_source,$($1_SRCS_FRM))
endef

define __bob_uic_sources_qt4
endef

define __bob_uic_objects
$(notdir $(subst .cpp,.o,$(call __bob_uic_sources_$(UI_STYLE),$1)))
endef

define __bob_to_rcc_source
$(patsubst %.qrc,%$(__res-cpp),$1)
endef

define __bob_rcc_sources_qt4
$(call __bob_to_rcc_source,$($1_SRCS_RCC))
endef

define __bob_rcc_objects
$(notdir $(subst .cpp,.o,$(call __bob_rcc_sources_$(UI_STYLE),$1)))
endef

define __bob_to_moc_source
$(subst .qhh,$(__moc-cpp),$(subst .h,$(__moc-cpp),$(subst .hh,$(__moc-cpp),$(subst .hpp,$(__moc-cpp),$1))))
endef

define __bob_moc_sources
$(call __bob_to_moc_source,$($1_SRCS_MOC))
endef

define __bob_moc_objects
$(notdir $(subst .cpp,.o,$(call __bob_moc_sources,$1)))
endef


# $1: Target -- $2: Module objectdir -- $3: Objects
define __bob_append_objects
$(eval $1_OBJS += $(call __bob_dirprefix,$2,$(filter-out /%,$3)))
endef

# $1: Target -- $2: Module objectdir
define __bob_append_src_objects
$(eval $1_OBJS += $(addprefix $(OBJDIR)/,$(call __bob_src_objects,$1)))
endef

# $1: Target -- $2: Module objectdir
define __bob_append_moc_objects
$(eval $1_OBJS += $(call __bob_append_objects,$1,$2,$(call __bob_moc_objects,$1)))
endef

# $1: Target -- $2: Module objectdir
define __bob_append_uic_objects
$(eval $1_OBJS += $(call __bob_append_objects,$1,$2,$(call __bob_uic_objects,$1)))
endef

# $1: Target -- $2: Module objectdir
define __bob_append_rcc_objects
$(eval $1_OBJS += $(call __bob_append_objects,$1,$2,$(call __bob_rcc_objects,$1)))
endef


# Expand source file wildcard patterns. Also verifies the existence of files.
#
# $1: Target -- $2: Module source directory -- $3: Varible
define __bob_expand_src_wildcard
$(eval abspath_sources := $(filter /%,$($1_$3))) \
$(if $(abspath_sources), \
	$(info $(W_PREFIX) $1: Ignoring absolute path sources $(abspath_sources))) \
$(eval $1_$3 := $(patsubst $(srcdir)/%,%,$(sort \
	$(wildcard $(abspath $(addprefix $2,$(filter-out /%,$($1_$3))))))))
endef
# ******************************************************************************


# If a target got forms (_SRCS_FRM) all its "foo"-object files must depend on
# the ui-object files, or some object files, which might be unknown or hard to
# find. This is currently (2008-06-01) a little unclear, I do not know how
# qt-includes can work.
#
# One solution is to depend all object-files on the ui-headers, but that is not
# preferable, since that would trigger a full rebuild when a single ui-file is
# updated. There is no way to be sure the object files are compiled in the
# correct order without parsing the source files, *and we do not wanna do that*
# (mostly because we can't). But currently it seems like only only some header
# files includes the .ui.h-files so depending all uic-object files on the
# uic-headers seems enough.
#
# $1: Target -- $2: Module objectdir
# ******************************************************************************
define setup_uic_depend_rules
$(if $($1_SRCS_FRM),\
	$(eval uic_objects := $(call __bob_uic_objects,$1)) \
	$(if $(uic_objects),\
		$(eval \
			$(call __bob_dirprefix,$2,$(uic_objects)): \
			$(call __bob_dirprefix,$2,$(call __bob_uic_headers,$1)))) \
	$(eval $1_CXXFLAGS += $(_I)$2) \
	$(eval $1_CFLAGS += $(_I)$2))
endef

# Have all object-files, both srcs and moc_srcs depend on any ui-header files if
# any. (In rare occations paralell builds will fail missing a header file).
#
# $1: Target -- $2: Module objectdir
define setup_uic_depend_rules_srcs
$(if $(strip $($1_SRCS_FRM)), \
	$(eval \
		$(call __bob_dirprefix,$2,$(call __bob_src_objects,$1)) \
		$(call __bob_dirprefix,$2,$(call __bob_moc_objects,$1)): \
		$(call __bob_dirprefix,$2,$(call __bob_to_uic_header,$(notdir $($1_SRCS_FRM))))))
endef

ifeq "$(UI_STYLE)" "qt4"
define setup_rcc_depend_rules
$(if $(strip $($1_SRCS_RCC)), \
	$(eval \
		$(call __bob_dirprefix,$2,$(call __bob_rcc_objects,$1)): \
		$(call __bob_dirprefix,$2,$(call __bob_to_rcc_source,$(notdir $($1_SRCS_RCC))))))
endef
endif
# ******************************************************************************


# QT-forms build rules setup, for the current module, all targets. Both uic and
# moc targets are setup. These rules are single-file-specific, i.e. each
# moc-file and ui-file is setup with an explicit rule.
#
# $1: List of targets -- $2: Module name
define setup_forms_rules_qt3
$(foreach t,$(sort $(foreach i,$1,$($(i)_SRCS_MOC))),
	$(eval $(call __bob_dirprefix,$($2_OBJDIR),$(call __bob_to_moc_source,$(notdir $(t)))): \
	$(call __bob_dirprefix,$($2_SRCDIR),$(t)) $$$$(@D)/.stamp
		$(if $(__bobSILENT),echo "$(C_PREFIX) [$2] Mocing $$(@F)";) \
		$(__bob.cmd.moc3) -f $$< $$(OUTPUT_OPTION))) \
$(foreach t,$(sort $(foreach i,$1,$($(i)_SRCS_FRM))),\
# Each ui-header file shall depend on its corresponding .ui-file
	$(eval $(call __bob_dirprefix,$($2_OBJDIR),$(call __bob_to_uic_header,$(notdir $(t)))): \
		$(call __bob_dirprefix,$($2_SRCDIR),$(t)) $$$$(@D)/.stamp
		$(if $(__bobSILENT),echo "$(C_PREFIX) [$2] Uicing header $$(@F)";) \
		$(__bob.cmd.uic3) $$< $$(OUTPUT_OPTION))

# Each ui-source file shall depend on its corresponding headerfile, which was
# generated and put in the objectdir.
	$(eval $(call __bob_dirprefix,$($2_OBJDIR),$(call __bob_to_uic_source,$(notdir $(t)))): \
		$(call __bob_dirprefix,$($2_OBJDIR),$(call __bob_to_uic_header,$(notdir $(t)))) $$$$(@D)/.stamp
		$(if $(__bobSILENT),echo "$(C_PREFIX) [$2] Uicing implementation $$(@F)";) \
		$$(__bob.cmd.uic3) $($2_SRCDIR)$(t) -i $$< $$(OUTPUT_OPTION))

# Each ui-moc-source file shall depend on its corresponding headerfile, which
# was generated and put in the objectdir. Same as the rule above just another
# file. This is not made a multiple target since make only calls each rule
# onces, and then the recipie must contain both commands.
	$(eval $(call __bob_dirprefix,$($2_OBJDIR),$(call __bob_to_uic_moc_source,$(notdir $(t)))): \
		$(call __bob_dirprefix,$($2_OBJDIR),$(call __bob_to_uic_header,$(notdir $(t)))) $$$$(@D)/.stamp
		$(if $(__bobSILENT),echo "$(C_PREFIX) [$2] Mocing uiced header $$(@F)";) \
		$(__bob.cmd.moc3) -f $$< $$(OUTPUT_OPTION)))
endef

define setup_resource_rules_qt3
$(foreach i,$1, $(eval
	$(foreach t,$($(i)_SRCS_RCC),\
		$(warning qt3 resources not supported - $(i)_SRCS_RCC := $(t)))))
endef
# ******************************************************************************


# $1: List of targets -- $2: Module name
define setup_forms_rules_qt4
# Each moc-file shall be moced and depend on its source file.
$(foreach f,$(sort $(foreach t,$1,$($(t)_SRCS_MOC))),
	$(eval $(call __bob_dirprefix,$($2_OBJDIR),$(call __bob_to_moc_source,$(notdir $(f)))): \
	$(call __bob_dirprefix,$($2_SRCDIR),$(f)) $$$$(@D)/.stamp
		$(if $(__bobSILENT),echo "$(C_PREFIX) [$2] Mocing $$(@F) ($1)";) \
		$(__bob.cmd.moc4) $$(foreach t,$1,$(call __target_inc,$$(t),$2) $$($$(t)_INCL_MOC)) $$< $$(OUTPUT_OPTION))) \
$(foreach f,$(sort $(foreach t,$1,$($(t)_SRCS_FRM))),\
# Each ui-header file shall depend on its corresponding .ui-file
	$(eval $(call __bob_dirprefix,$($2_OBJDIR),$(call __bob_to_uic_header,$(notdir $(f)))): \
		$(call __bob_dirprefix,$($2_SRCDIR),$(f)) $$$$(@D)/.stamp
		$(if $(__bobSILENT),echo "$(C_PREFIX) [$2] Uicing $$(@F) ($1)";) \
		$(__bob.cmd.uic4) $$< $$(OUTPUT_OPTION)))
endef

# $1: List of targets -- $2: Module name
define setup_resource_rules_qt4
$(eval __PartName := $(if $(findstring .,$2),$(NAME),$2))
$(foreach t,$(sort $(foreach i,$1,$($(i)_SRCS_RCC))),
	$(eval $(call __bob_dirprefix,$($2_OBJDIR),$(call __bob_to_rcc_source,$(notdir $(t)))): \
	$(call __bob_dirprefix,$($2_SRCDIR),$(t)) $($2_OBJDIR)/.stamp
		$(if $(__bobSILENT),echo "$(C_PREFIX) [$2] Rccing resource $$(@F) ($1)";) \
		grep file $$< | sed -e "s|<file>|$$@: $$(dir $$<)|" -e "s|</file>||" > $($2_OBJDIR)$(notdir $(t)).d; \
		$(__bob.cmd.rcc4) -name $(__PartName) $$< $$(OUTPUT_OPTION)))
endef
# ******************************************************************************


# Generate install rules. Which are actually dependencies on the destination
# files. Rules for "copying" files to this destination is specified elsewhere
# (are global), which is not a problem because there can only be ONE destination
# for each invocation of make. Plugins have a certain twist, the user is allowed
# to set the varible PLUGINSCATEGORY which will be part of the directory name.
#
# $1: Module name -- $2: Targets
# ******************************************************************************
define generate_install_targets
$(eval PLUGINS_SHAREDIR ?= $(__name))
$(eval plugindir := $(datadir)/$(PLUGINS_SHAREDIR)/plugins)
$(eval tmp := $2 $(filter-out lib%plugin.a,$(patsubst lib%.so,lib%.a,$(filter lib%.so,$2))))
$(if $(DISABLE_ARCHIVES),$(eval tmp := $(filter-out lib%.a,$(tmp))))
$(eval __bobPLUGINTARGETS := $(filter %plugin.so,$(tmp)))
$(eval __bobBINTARGETS    := $(filter-out lib%.so lib%.a %plugin.so,$(tmp)))
$(eval __bobLIBTARGETS    := $(filter lib%,$(filter-out %plugin.so,$(tmp))))
$(if $(__bobPLUGINTARGETS),$(call __bob_install_targets_specific,plugindir,$1,$(__bobPLUGINTARGETS)))
$(if $(__bobBINTARGETS),   $(call __bob_install_targets,bindir,$1,$(__bobBINTARGETS)))
$(if $(__bobLIBTARGETS),   $(call __bob_install_targets,libdir,$1,$(__bobLIBTARGETS)))
$(if $(wildcard $($1_SRCDIR)include),$(call __bob_install_include_files,$1))
endef

# Setup install dependencies for a list of targets. The dependencies are real
# files/prerequisites (last row) which resides in the $1 location.
#
# $1: What dir -- $2: Module name -- $3: List of targets
define __bob_install_targets
.PHONY: $(addprefix install-,$3)
__module-install-$2:      $(addprefix install-,$(filter-out test.%,$3))
__module-install-test-$2: $(addprefix install-,$(filter     test.%,$3))
$(foreach t,$3,
install-$t: $t
install-$t: $(call __bob_dirprefix,$(DESTDIR)$($1)/,$t))
endef

# Setup install dependencies and target rules for each target. This macro must
# be used when the user can modify the directory structure via
# configuration. Then each target needs a uniqe rule for installation. Else not
# much differ from the generic macro above.
#
# $1: What dir -- $2: Module name -- $3: List of targets
define __bob_install_targets_specific
.PHONY: $(addprefix install-,$3)
__module-install-$2:      $(addprefix install-,$(filter-out test.%,$3))
__module-install-test-$2: $(addprefix install-,$(filter     test.%,$3))
$(foreach t,$3,
$(eval dest := $(DESTDIR)$($1)/$t)
install-$t: $(dest)
$(dest): $(TGTDIR)/$t | $(DESTDIR)$($1)._INSTALL_DIRECTORY ; @$(INSTALL_EXEC) $(TGTDIR)/$t $($1))
endef

# Setup install target for a modules include files, and link that target to the
# global install-target.
#
# $1: Module name
define __bob_install_include_files
.PHONY: __module-install-include-files-$1
$(eval __all_src_include_files := \
	$(subst ./,,$(shell $(__bob.cmd.find) $($1_SRCDIR)include -type f -! -wholename "*/.svn/*")))
$(eval __all_dst_include_files := \
	$(addprefix $(DESTDIR)$(includedir)/, \
		$(patsubst include/%,%, \
			$(patsubst $($1_SRCDIR)include/%,%,$(__all_src_include_files)))))
__module-install-$1: __module-install-include-files-$1
__module-install-include-files-$1: $(__all_dst_include_files)
$(__all_dst_include_files): $(DESTDIR)$(includedir)/%:$($1_SRCDIR)include/%
	@$(__bob.cmd.install) -Dm644 $$< $$@
endef
# ******************************************************************************


# Setup targets dependencies, specified by their link-time depedencies. The
# macro uses the linker arguments to find which libraries the target uses and
# if those libraries are internal, i.e. built by this bob-project, those
# library targets becomes dependencies to the current target being processed.
#
# $1: List of targets
# ******************************************************************************
define pp_setup_target_link_dependencies
$(foreach t,$1,\
	$(eval __bob_libinternal := $(sort $(filter $(patsubst $(_l)%,lib%.so,$($t_LIBS) $($t_LINK)),$1)))\
	$(eval __bob_libexternal := $(sort $(filter-out $1,$(patsubst $(_l)%,lib%.so,$(filter $(_l)%,$($t_LIBS) $($t_LINK))))))\
	$(if $(__bob_libinternal),\
		$(eval __bob_$t_internaldeps := $(__bob_libinternal)) \
		$(eval $(addprefix $(TGTDIR)/,$t):$(addprefix $(TGTDIR)/,$(__bob_libinternal))) \
		$(eval __bob_$t_internalincl := \
			$(sort $(foreach dep,$(__bob_libinternal),$(foreach dir,$(__$(dep)_interfacedirs),$(_I)$(dir))))) \
		$(eval __bob_$t_ppincl     += $(sort $(__bob_$t_internalincl))) \
		$(eval __bobLISTALLINTINCL += $(sort $(__bob_$t_internalincl)))) \
	$(if $(__bob_libexternal),\
		$(eval __bob_$t_externaldeps := $(__bob_libexternal))))
endef


# Setup a list of bin and lib suffixed paths for export to bobshell. The
# basedirs (homes) can come from either makerules-files or environment.
#
# $: N/A
# ******************************************************************************
define pp_setup_libbin_paths
$(eval export __bobLISTHOMELIBS := \
	$(abspath \
		$(addsuffix /lib,$(sort $(__bobLISTALLHOMES))) \
		$(addsuffix /lib64,$(sort $(__bobLISTALLHOMES))))) \
$(eval export __bobLISTHOMEBINS := \
	$(abspath $(addsuffix /bin,$(sort $(__bobLISTALLHOMES)))))
endef


# For including submodules from a... not submodule. But which could be a
# submodule itself when related to another parent module... also fix so
# submodule know which is the current module, i.e. its parent module, which
# could be a submodule to a parent module in itself too, but not making this
# module a subsubmodule but only a submodule because a module can only be a
# submodule... this since a module cannot know its own submodules submodules,
# nor its parents parents.
#
# Yes, sometimes it is tricky, I know... lucky this parent module stuff is not
# in effect at the moment.
#
# $1: Module name -- $2: List of submodules
# ******************************************************************************
define __bob_include_submodules
$(eval __submodules := $(wildcard $(addsuffix /$(__bob.file.rules),$(addprefix $($1_SRCDIR),$2))))
.PHONY: $(__submodules)
-include $(__submodules)
endef
# ******************************************************************************


# Helper for finding out what library directory to use, in case of 32 and 64-bit
# compilations. Some tools are installed with lib and lib64 directories for 32
# and 64-bit repspectively.
#
# $1: Home directory
define __gethomelibdir
$(if $(findstring x86_64,$(__bob.buildarch)),\
	$(firstword $(wildcard $1/lib64 $1/lib)),\
	$(firstword $(wildcard $1/lib $1/lib64)))
endef

# Check requirements. This means that a <R>_HOME variable must exist. Else we
# cannot build this software and that is an error.
# ******************************************************************************
__bob_ALLREQ_INCLPATH :=
__bob_ALLREQ_RLNKPATH :=
define setup_requires
$(call setup)
endef
define setup
$(if $(__bobDISABLECHECKREQUIREMENTS),,\
$(if $(SOFTWARE_HOMES),\
	$(foreach s,$(patsubst %/,%,$(subst :,$(space),$(SOFTWARE_HOMES))),\
		$(foreach x,$(notdir $(wildcard $s/*)),\
			$(eval homevariable := $(call __uc,$x)_HOME)\
			$(if $($(homevariable)),,\
				$(eval y := $(firstword $(dir $(wildcard $s/$x/include $s/$x/latest/include))))\
				$(if $y,$(eval $(homevariable) := $(realpath $y)))))))\
$(foreach r,$(sort $(REQUIRES)),\
	$(eval R := $(call __uc,$(call __get_name,$r)))\
	$(eval __inclflag := $(_I))\
	$(foreach s,$(sort $(SYSTEM_HEADERS)),\
		$(if $(findstring $r,$s),\
			$(eval __inclflag := $(_isystem)),))\
	$(if $(findstring undefined,$(origin $R_HOME)),\
		$(eval requirement_verification_error := yes)\
		$(info $(shell printf "%s %s -> %-12s -- %s undefined\n" "$(W_PREFIX)" "$(NAME)" "$r" "$R_HOME")),\
		$(eval home := $($R_HOME))\
		$(eval __bobLISTALLHOMES += $($R_HOME))\
		$(eval homeincdir := $(realpath $(home)/include))\
		$(if $(homeincdir),\
			$(eval export $R_INCL := $(__inclflag)$(homeincdir))\
			$(eval export __bob_ALLREQ_INCLPATH += $($R_INCL)))\
		$(eval homelibdir := $(call __gethomelibdir,$(home)))\
		$(if $(homelibdir),\
			$(eval export $R_LIBSPATH := $(_L)$(homelibdir))\
			$(eval export $R_RLNKPATH := $(__bobRPATHLINKFLAG)$(homelibdir))\
			$(eval export $R_LIBS := $($R_LIBSPATH) $($R_RLNKPATH))\
			$(eval export __bob_ALLREQ_RLNKPATH += $($R_RLNKPATH)))))\
$(if $(requirement_verification_error),\
	$(info $(W_PREFIX) ********************************************************************)\
	$(info $(W_PREFIX) There are missing build requirements, see the messages above.)\
	$(info $(W_PREFIX) You must either provide _HOME-variables pointing to already built)\
	$(info $(W_PREFIX) software or the source itself.)\
	$(info $(W_PREFIX) ********************************************************************)\
	$(error Missing build requirements error)))
endef


# Setup all dependencies for a target. A shortcut for doing "make <T>" rather
# than "make TGTDIR/<T>". Create target specific variables which holds all
# compile and link flags for the target. If inter module optimization is wanted
# use a slighlty tweaked depedency setup
#
# $1: Target, $2: Module
# ******************************************************************************
define setup_target
.PHONY: $1
$1: $(TGTDIR)/$1
# Transform _USES to include directives
$(if $($1_USES),$(eval $1_INCL += $(foreach u,$($1_USES),$($(call __uc,$u)_INCL))))
# Append only rpath directives derived from _USES.
$(if $($1_USES),$(eval $1_LIBS += $(__bob_ALLREQ_RLNKPATH)))
# Implicit _LINKPATH if _LINK, derive the link path from the uses variable.
$(if $($1_LINK),\
	$(eval $1_LINK := $(addprefix $(_l),$($1_LINK))) \
	$(eval $1_LINKPATH += $(foreach u,$($1_USES),$($(call __uc,$u)_LIBSPATH))))
# Target .d-files
$(eval __dfiles := $(call __bob_target_dfiles,$1,$($2_OBJDIR)))
.PHONY: $(__dfiles)
-include $(__dfiles)
# Target compile flags
$(eval __defines := $(call __setup_target_def,$1))
$(eval __include := $(call __setup_target_inc,$1,$2))
$(TGTDIR)/$1: __target.cflags    = $(_CFLAGS)   $(strip $$($1_CFLAGS)   $(__include) $($1_INCL) $(__defines))
$(TGTDIR)/$1: __target.cxxflags  = $(_CXXFLAGS) $(strip $$($1_CXXFLAGS) $(__include) $($1_INCL) $(__defines))
$(TGTDIR)/$1: __target.ldflags   = $(_LDFLAGS) $(CXXFLAGS) $(_CXXFLAGS) $(strip $$($1_LDFLAGS) $$($1_LINKPATH) $$($1_LINK) $$($1_LIBS))
$(TGTDIR)/$1: __target.gnatflags = $(strip $$($1_GNATFLAGS))
# Depend on .o-files
$(TGTDIR)/$1: $($1_OBJS)
# DSOs needs special care:
# * Setup a variable for the DSOs interface directory.
# * Setup the version variable if not set.
# * Always create a corresponding archive.
$(if $(filter %.so,$(filter-out %plugin.so,$1)),
$(eval __$1_interfacedirs := $(wildcard $($2_SRCDIR)include $($2_SRCDIR)include_internal))
$(if $(findstring undefined,$(origin $1_VERSION)),$(eval $1_VERSION := $(__version)))
$(if $(AR),$(if $(DISABLE_ARCHIVES),,\
	$(eval $(patsubst %.so,%.a,$1): $(TGTDIR)/$(patsubst %.so,%.a,$1)) \
	$(eval $(TGTDIR)/$1: $(TGTDIR)/$(patsubst %.so,%.a,$1)) \
	$(eval $(TGTDIR)/$(patsubst %.so,%.a,$1): $($1_OBJS)))))
endef

# Helpers for target include flags. Observe the order for internal and external
# includes. First the target's all directories, including the source dir. Then
# all other internal includes and finally the external includes given explicitly
# by the developer via FOO_INCL variables. ALSO, make sure you know the
# difference between $$ and $ expansion of the variable. In this case
# bob_$t_INCL have a double $$ which will delay the expansion one step, and that
# is very neccessary in this case. See where and how that variable is defined,
# it contains references to stuff which is not completely defined at the time of
# assignment.
#
# $1: Target, $2: Module
define __setup_target_inc
$(addprefix $(_I),$(wildcard \
	$($2_SRCDIR) \
	$($2_SRCDIR)src \
	$($2_SRCDIR)include \
	$($2_SRCDIR)include_internal \
	.)) \
$$$$(__bob_$1_ppincl)
endef
# Helper for target defines flags
# $1: Target
define __setup_target_def
$(addprefix $(_D),$(sort $($1_DEFINES) $(_DEFINES) $(DEFINES)))
endef
# ******************************************************************************

# Cppcheck.
#
# $1: Targets, $2: Module
define setup_cppcheck
$(foreach t,$1,
cppcheck: $t.cppcheck
$t.cppcheck:
	@echo "$(X_PREFIX) $$(@F)";
	$(__bob.cmd.cppcheck) $(CPPCHECKFLAGS) -I$($2_SRCDIR) $($t_SRCS))
endef


# ******************************************************************************
#
# User initiated macros
#
# ******************************************************************************

# Fetch source files within a module.  !!! OBS !!! This function is a end-user
# function, therefore it must be simple enough and not confuse. The _SRCDIR
# variable has been used in the macro, and it should be safe since this macro
# shall only be called from "user space".
#
# $1: Directory -- $2: Source specification
# ******************************************************************************
define getsource
$(if $1,$(eval dir:=$1),$(eval dir:=.)) \
$(call __bob_dirprefix,$(dir),$(notdir $(wildcard $(_SRCDIR)$(dir)/$2)))
endef
# ******************************************************************************


# Get all moc sources
#
# $1: Directory -- $2: Source specification
# ******************************************************************************
define getmocable
$(if $1,$(eval dir:=$1),$(eval dir:=.)) \
$(call __bob_dirprefix,$(dir),$(notdir $(shell egrep -sl "^[[:space:]]*Q_OBJECT" $(_SRCDIR)$(dir)/$2)))
endef
# ******************************************************************************
