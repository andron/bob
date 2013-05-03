# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Help and info targets
# ************************************************************
help:
	@echo
	@echo "More help"
	@echo "------------------------------------------------------------------------"
	@echo "   % make help-buildtypes    Available buildtypes and their meaning"
	@echo "   % make help-compiler      Compiler and linker used."
	@echo "   % make help-paths         Paths used at install."
	@echo "   % make help-targets       List all targets which gets built."
	@echo
	@echo "   % make help-make          Special information about Make."
	@echo
	@echo " Plugin help"
	@echo "   % make help-plugins           shows all loaded plugins"
	@echo "   % make help-plugin-<plugin>   show help for specific plugin"
	@echo


help-plugins:
	@echo
	@echo "Plugin help"
	@echo "------------------------------------------------------------------------"

	@echo 
	@echo -e "   ** Loaded plugins **"; \
	idy=1; for i in \
		$(sort $(BOBPLUGINS)); do \
		echo "     $$idy: $$i "; \
		idy=`expr $$idy + 1`; \
	done; \

	@echo
	@echo -e "   ** Available plugins **"; \
	idx=1; for i in \
		$(filter-out README,$(notdir $(sort $(wildcard $(__bob.plugin.dir)/*)))); do \
		echo "     $$idx: $$i "; \
		idx=`expr $$idx + 1`; \
	done; \

	@echo
	@echo " Set environment variable BOBPLUGINS to a space separated list of"
	@echo " plugins you want loaded."
	@echo
	@echo "   % make help-plugin-<plugin>   show help for specific plugin"
	@echo 



help-buildtypes:
	@echo ""
	@echo "Buildtypes"
	@echo "------------------------------------------------------------------------"
	@echo ""
	@echo " By running make with buildtype set to one of the options below you can "
	@echo " control what sort of build you want                                    "
	@echo
	@echo "  release   - Normal release build"
	@echo "  $(__compiler_name) $(__$(__compiler_name)_release)"
	@echo
	@echo "  profiling - Like normal release but enables profiling"
	@echo "  $(__compiler_name) $(__$(__compiler_name)_profiling)"
	@echo
	@echo "  pedantic  - Like normal release but be more \"pedantic\""
	@echo "              (If your code builds here, you rule!)"
	@echo "  $(__compiler_name) $(__$(__compiler_name)_pedantic)"
	@echo
	@echo "  debug     - No inlining, DEBUG defined, no optimization and ggdb3 format"
	@echo "  $(__compiler_name) $(__$(__compiler_name)_debug)"
	@echo



help-compiler:
	@echo
	@echo " *** Compiler ***"
	@echo "------------------------------------------------------------------------"
	@echo "C-files compiler (with default flags):"
	-$(COMPILE.c) $(COMPILERVERSIONFLAG)
	@echo
	@echo "C++-files compiler (with default flags):"
	-$(COMPILE.cpp) $(COMPILERVERSIONFLAG)
	@echo
	@echo " *** Linking ***"
	@echo "------------------------------------------------------------------------"
	@echo "C++-style files linker (with default flags):";
	-$(LINK.cpp) $(COMPILERVERSIONFLAG)
	@echo
ifeq "$(CC)" "CC"
	@echo " ... Notice the error? See the strength of open source now?"
endif



help-paths:
	@echo
	@echo " *** Paths ***"
	@echo "------------------------------------------------------------------------"
	@echo "   srcdir       $(srcdir)"
	@echo
	@echo "   builddir     $(builddir)"
	@echo "     |-OBJDIR   $(OBJDIR)"
	@echo "     \`-TGTDIR   $(TGTDIR)"
	@echo
	@echo "   Installation directories, set DESTDIR to relocate"
	@echo "   --------------------------------------------------"
	@echo "   DESTDIR      $(DESTDIR)"
	@echo "   prefix       $(DESTDIR)$(prefix)"
	@echo "   exec_prefix  $(DESTDIR)$(exec_prefix)"
	@echo "   bindir       $(DESTDIR)$(bindir)"
	@echo "   sbindir      $(DESTDIR)$(sbindir)"
	@echo "   libdir       $(DESTDIR)$(libdir)"
	@echo "   libexecdir   $(DESTDIR)$(libexecdir)"
	@echo "   datarootdir  $(DESTDIR)$(datarootdir)"
	@echo "   datadir      $(DESTDIR)$(datadir)"
	@echo "   sysconfdir   $(DESTDIR)$(sysconfdir)"
	@echo "   includedir   $(DESTDIR)$(includedir)"
	@echo "   docdir       $(DESTDIR)$(docdir)"
	@echo



help-make:
	@echo
	@echo " *** Make specific stuff ***"
	@echo "------------------------------------------------------------------------"
	@echo "Textual output types used by Bob."
	@echo "  Debug        $(D_PREFIX)"
	@echo "  Warning      $(W_PREFIX)"
	@echo "  Compile      $(C_PREFIX)"
	@echo "  Link         $(L_PREFIX)"
	@echo "  Install      $(I_PREFIX)"
	@echo "  Text output  $(T_PREFIX)"
	@echo "  Test output  $(X_PREFIX)"
	@echo "  Test output  $(V_PREFIX)"
	@echo
	@echo "Include directories used by *make*, not for compiling"
	@echo "$(.INCLUDE_DIRS)"
	@echo
	@echo "Special variables ... (quite many)"
	@echo "$(.VARIABLES)"



help-targets:
	@echo
	@echo " *** Available targets ***"
	@echo "------------------------------------------------------------------------"
	@echo -e " ** Shared libraries **"; \
	idx=1; for i in \
		$(sort $(filter %.so,$(__bobLIST_TARGETS))); do \
		echo "   $$idx. $$i"; \
		idx=`expr $$idx + 1`; \
	done; \
	echo -e "\n ** Executables **"; \
	idx=1; for i in \
		$(sort $(filter-out %.a,$(filter-out %.so,$(__bobLIST_TARGETS)))); do \
		echo "   $$idx. $$i"; \
		idx=`expr $$idx + 1`; \
	done
