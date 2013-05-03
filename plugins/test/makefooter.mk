# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Filter out test.* targets from the TARGETS list and connect these ones to
# the global target test:.
TEST_TARGETS := $(filter test.%,$(TARGETS))
TARGETS := $(filter-out $(TEST_TARGETS),$(TARGETS))

# Save the current module's test targets with full path.
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
