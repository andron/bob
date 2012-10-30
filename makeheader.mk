# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Alter the makefile list so that the 'last' file is the modules makerules
# file and not the header or footer included by it.
_MAKEFILE_LIST := $(filter-out $(HEADER) $(FOOTER),$(MAKEFILE_LIST))

# Empty makefile list, we are only interested in the last included file, ever.
MAKEFILE_LIST :=

# Phony all makerules.mk
.PHONY: $(lastword $(_MAKEFILE_LIST))

# Work out the module name from the directory name.
_MODULE := $(lastword $(subst /, ,$(dir $(lastword $(_MAKEFILE_LIST)))))

# Source directory for the module, make SURE there is an / at the end.
_SRCDIR := $(subst //,/,$(dir $(lastword $(_MAKEFILE_LIST)))/)
$(_MODULE)_SRCDIR := $(_SRCDIR)

# Object and other directories for the module.
_OBJDIR := $(subst /./,/,$(OBJDIR)/$(_SRCDIR))
$(_MODULE)_OBJDIR := $(_OBJDIR)

# Object and other directories for the module.
_TGTDIR := $(TGTDIR)
$(_MODULE)_TGTDIR := $(_TGTDIR)

# Clear module specific targets and dependencies...
TARGETS :=
ALL_TARGETS :=
SUBMODULES :=
_CFLAGS :=
_CXXFLAGS :=
_DEFINES :=
_LDFLAGS :=
_LIBS :=
_INCL :=
_LINK :=

# The full module name, i.e. the name reflects a complete path.
_MODULE_FULLNAME := $(subst /,-,$(patsubst %/,%,$(_SRCDIR)))

ifdef BOBPLUGINS
-include $(__bob.plugin.headers)
endif

# Include the info file if such exist, and only if we are at the top level.
ifeq "$(_MODULE_FULLNAME)" "."
_MAKEFINFO := $(wildcard $(__bob.file.infos))
ifneq "$(_MAKEFINFO)" ""
# Header and footer files must be empty in this case, the contents of the info
# file needs to have a header and a footer injections in the meta case for
# processing.
HEADER :=
FOOTER :=
include $(_MAKEFINFO)
$(call setup_requires)
HEADER := $(__bob.file.headerb)
FOOTER := $(__bob.file.footerb)
endif
endif
