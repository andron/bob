# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Default and general rules. General rules are those *not* specific to any
# module, i.e. all targets, directories and misc files.


# Empty suffixes to get rid of builtin implicit rules.
.SUFFIXES:

# All stamp files should be precious. (Even the module directory stamp-files are
# covered by this rule).
.PRECIOUS: %.stamp

# Rule for all stamp files, will create object dirs and target dirs. Depending
# on any path ending with .stamp will create the directory part and create a
# empty file named .stamp in that directory.
%.stamp:
	@$(INSTALL_DIRS) $(dir $@) && touch $@


# *** COMPILE RULES ***
# All object files must go into a different directory then the cpp-file, thus
# the builtin implicit rules needs modification. The __target_CXXFLAGS are
# dependents of each specific target which are setup by macros during parsing.
$(OBJDIR)/%.o:$(OBJDIR)/%.cpp | $$(@D)._INSTALL_DIRECTORY
	$(if $(__bobSILENT),echo "$(C_PREFIX) [OBJDIR] [generated] $(@F)";) $(COMPILE.cpp) $(__target_CXXFLAGS) $(_o) $@ $<
$(OBJDIR)/%.o:$(OBJDIR)/%.c   | $$(@D)._INSTALL_DIRECTORY
	$(if $(__bobSILENT),echo "$(C_PREFIX) [OBJDIR] [generated] $(@F)";) $(COMPILE.c) $(__target_CFLAGS) $(_o) $@ $<
$(OBJDIR)/%.o:%.cpp | $$(@D)._INSTALL_DIRECTORY
	$(if $(__bobSILENT),echo "$(C_PREFIX) [$(dir $<)] $(@F)";) $(COMPILE.cpp) $(__target_CXXFLAGS) $(_o) $@ $<
$(OBJDIR)/%.o:%.cc  | $$(@D)._INSTALL_DIRECTORY
	$(if $(__bobSILENT),echo "$(C_PREFIX) [$(dir $<)] $(@F)";) $(COMPILE.cpp) $(__target_CXXFLAGS) $(_o) $@ $<
$(OBJDIR)/%.o:%.c   | $$(@D)._INSTALL_DIRECTORY
	$(if $(__bobSILENT),echo "$(C_PREFIX) [$(dir $<)] $(@F)";) $(COMPILE.c) $(__target_CFLAGS) $(_o) $@ $<

# *** SHARED PLUGIN LIBRARIES ***
# Target for building plugins, almost as ordinary DSOs. Plugins does not have a
# so-name containing the version number.
$(TGTDIR)/%plugin.so: | $$(@D)._INSTALL_DIRECTORY
	$(if $(__bobSILENT),echo "$(L_PREFIX) Plugin  $(notdir $@)";) $(LINK.cc) $(__target_IMOPTFLAGS) $(DYNAMICLIBFLAG) $(_o) $@ $(SONAMEFLAG:<soname>=$(notdir $@)) $(filter %.o,$^) $(__target_LDFLAGS);


# *** SHARED LIBRARIES ***
# Target for building a shared library from .o-files
$(TGTDIR)/%.so: SOBASE  = $(if $(findstring file,$(origin $(notdir $@)_SOBASE)),$($(notdir $@)_SOBASE),$(notdir $@))
$(TGTDIR)/%.so: SOMAJOR = $(word 1,$(subst ., ,$($(notdir $@)_VERSION)))
$(TGTDIR)/%.so: SOMINOR = $(word 2,$(subst ., ,$($(notdir $@)_VERSION)))
$(TGTDIR)/%.so: SOPATCH = $(word 3,$(subst ., ,$($(notdir $@)_VERSION)))
$(TGTDIR)/%.so: | $$(@D)._INSTALL_DIRECTORY
	$(if $(__bobSILENT),echo "$(L_PREFIX) DSO     $(notdir $@)";) $(LINK.cc) $(__target_IMOPTFLAGS) $(DYNAMICLIBFLAG) $(_o) $@.$(SOMAJOR).$(SOMINOR).$(SOPATCH) $(SONAMEFLAG:<soname>=$(SOBASE).$(SOMAJOR)) $(filter %.o,$^) $(__target_LDFLAGS);
	@[ -e $@.$(SOMAJOR).$(SOMINOR).$(SOPATCH) ] \
	&& $(__bob.cmd.ln) $(notdir $@).$(SOMAJOR).$(SOMINOR).$(SOPATCH) $@.$(SOMAJOR) \
	&& $(__bob.cmd.ln) $(notdir $@).$(SOMAJOR) $@;


# *** ARCHIVES ***
$(TGTDIR)/%.a: | $$(@D)._INSTALL_DIRECTORY
	$(if $(__bobSILENT),echo "$(L_PREFIX) Archive $(notdir $@)";) $(ARCREATE) $@ $(filter %.o,$^)


# *** ADA EXECUTABLES ***
# Target for building targets from ada files. This is a compile-and-link target,
# thus; no corresponding compile rules exists.
$(TGTDIR)/%: $$($$(notdir $$@)_SRCDIR)/%.adb | $$(@D)._INSTALL_DIRECTORY
	@echo "$(L_PREFIX) Building and linking $(notdir $@)"; \
	mkdir -p $($(@F)_OBJDIR); \
	cd $($(@F)_OBJDIR) && gnatmake -c $(GNATFLAGS) $(__target_GNATFLAGS) $($(@F)_INCL) $(_I)$(abspath $($(@F)_SRCDIR)) $(_I)$(abspath $($(@F)_SRCDIR))/include $(_I)$(abspath $($(@F)_SRCDIR))/include_internal $(__ALL_INCL) -gnato -gnatf -gnatn $(@F); \
	cd $($(@F)_OBJDIR) && gnatmake -b $(GNATFLAGS) $(@F); \
	cd $($(@F)_OBJDIR) && gnatlink $(GNATFLAGS) $(__target_GNATFLAGS) -o $(abspath $@) $(@F).ali -L$(TGTDIR) $($(notdir $@)_LDFLAGS) $($(notdir $@)_LIBS) $($(notdir $@)_LINK) $(__ALL_LIBS)


# *** EXECUTABLES ***
# Target for building executables from .o-files and LIBS
$(TGTDIR)/%: | $$(@D)._INSTALL_DIRECTORY
	$(if $(__bobSILENT),echo "$(L_PREFIX) Exec    $(notdir $@)";) $(LINK.cc) $(__target_IMOPTFLAGS) $(_o) $@ $(filter %.o,$^) $(__target_LDFLAGS)


# *** INSTALLS ***
# Macro for pretty-printing installations
define pretty_print_installation
$(if $(__bobSILENT),@,@echo "$(I_PREFIX) $(subst $(builddir)/,,$< $(dir $@))";)
endef
# Target for installing stuff.
$(DESTDIR)$(bindir)/%: $(TGTDIR)/% | $(DESTDIR)$(bindir)
	$(call pretty_print_installation)$(INSTALL_EXEC) $< $@

$(DESTDIR)$(sbindir)/%: $(TGTDIR)/% | $(DESTDIR)$(sbindir)
	$(call pretty_print_installation)$(INSTALL_EXEC) $< $@

$(DESTDIR)$(libdir)/%.so: $(TGTDIR)/%.so | $(DESTDIR)$(libdir)
	$(call pretty_print_installation)$(__bob.cmd.rsync) $<* $(dir $@)

$(DESTDIR)$(libdir)/%.a: $(TGTDIR)/%.a | $(DESTDIR)$(libdir)
	$(call pretty_print_installation)$(INSTALL_DATA) $< $@


# *** DIRECTORY INSTALLS ***
# How the actual directories are installed.
$(DESTDIR)$(applicationsdir) \
$(DESTDIR)$(bindir)          \
$(DESTDIR)$(datadir)         \
$(DESTDIR)$(docdir)          \
$(DESTDIR)$(includedir)      \
$(DESTDIR)$(libdir)          \
$(DESTDIR)$(libexecdir)      \
$(DESTDIR)$(man1dir)         \
$(DESTDIR)$(sbindir)         \
$(DESTDIR)$(sysconfdir)      \
$(DESTDIR)$(localstatedir)   \
$(TGTDIR)                    \
$(OBJDIR):
	@echo "$(I_PREFIX) Directory $(subst $(builddir)/,,$@)"; \
	$(INSTALL_DIRS) $@

# *** Alternative version of directory install...
%._INSTALL_DIRECTORY:
	@if [ ! -d $* ]; then $(INSTALL_DIRS) $*; fi
