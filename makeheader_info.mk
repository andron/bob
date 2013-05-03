# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Alter the makefile list so that the 'last' file is the modules makerules file
# and not the header or footer included by it.
_MAKEFILE_LIST := $(filter-out $(HEADER) $(FOOTER),$(MAKEFILE_LIST))

# Empty makefile list, we are only interested in the last included file, ever.
MAKEFILE_LIST :=

# Work out the module name from the directory name.
_MODULE := $(lastword $(subst /, ,$(dir $(lastword $(_MAKEFILE_LIST)))))

# Source directory for the module, make SURE there is an / at the end.
$(_MODULE)_SRCDIR := $(subst //,/,$(dir $(lastword $(_MAKEFILE_LIST)))/)
_SRCDIR := $($(_MODULE)_SRCDIR)

# Reset interesting variables
NAME :=
VERSION :=
RELEASE :=
REQUIRES :=
GROUP :=
