# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# *** TEST VARIABLES ***
__bob_test_classes := reg tdd mod tmp

# *** TEST MACROS ***
define __bob_test_templ
$(addsuffix .%,$(addprefix $1.,$(__bob_test_classes)))
endef

# Test and Check entries
# ******************************************************************************
# Test and check depends on the corresponding classes.
test check: $(addprefix $$@.,$(__bob_test_classes));

# The subclasses does nothing, different build target are just connected to it
# in the plugin footer to trigger the build.
$(addprefix test.,$(__bob_test_classes)) $(addprefix check.,$(__bob_test_classes)):

# Short circuit the check and execute targets. This makes it possible todo
# "make check.tdd" and get all tdd-tests built and executed.
check.%: __execute.%;

# Main target for checks, depends on its corresponding test target so that the
# correct test class gets built. The test's home directory, i.e. the directory
# in the project structure, is stored in the _TSTDIR environment variable. If
# a _SCRIPT_SETUP and/or _SCRIPT_TEARDOWN is specified those gets sourced
# accordingly. If the test needs argument those are passed via _ARGUMENTS.
__execute.%: test.%
	@echo "$(X_PREFIX) TEST=$<"
	-@if [ -z "$$BOBBUILDBASH" ]; then \
		export LD_LIBRARY_PATH=$$LD_LIBRARY_PATH:$(TGTDIR):$(subst $(space),:,$(__bobLISTHOMELIBS)); fi; \
	export _TGTDIR=$(TGTDIR); \
	if [ -n "$($<_SRCDIR)" ]; then export _TSTDIR=$($<_SRCDIR); fi; \
	if [ -f "$($<_SCRIPT_SETUP)" ]; then . $($<_SCRIPT_SETUP);    fi; \
	retval=0; \
	test=$(TGTDIR)/$<; \
	if [ -f $$test ]; then \
		$(TST_WRAPPER) $$test $($<_ARGUMENTS); \
		if [ $$? == 0 ]; then \
			echo "$(X_PREFIX) `basename $$test`:OK"; \
		else \
			echo "$(X_PREFIX) `basename $$test`:FAILED"; \
			retval=1; \
		fi; \
	fi; \
	if [ -f "$($<_SCRIPT_TEARDOWN)" ]; then . $($<_SCRIPT_TEARDOWN); fi; \
	if [ $$retval != 0 ]; then exit -1; fi;


.PHONY: help-plugin-test test check \
	$(addprefix test.,$(__bob_test_classes)) \
	$(addprefix check.,$(__bob_test_classes)) \
	$(addprefix __execute.,$(__bob_test_classes))


# Help
help-plugin-test:
	@echo -e \
	"\n TEST plugin"                                                             \
	"\n------------------------------------------------------------------------" \
	"\n"
