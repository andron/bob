# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Default settings file for PRQA source code analyzer.
qacpp: QACPPSETTINGS ?= settings.via
# Reassign CXX to use a wrapper script.
qacpp: CXX = qaw qacpp -via $(QACPPSETTINGS) -cargs echo
# Rerun with the adjusted variables.
qacpp:
	@echo "$(__bob.prefix) Running static code analysis"
	@$(MAKE) -C . CXX="$(CXX)"
