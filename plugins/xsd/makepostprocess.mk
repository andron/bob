# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Now all object variables are defined, depend object files on xsd header files.
$(foreach t,$(__bob_xsd_alltargets), \
	$(eval $($t_OBJS):$(__bob_xsd_$t_headers)))

# Set up install dependencies for schema files.
$(foreach t,$(__bob_xsd_allschemas), \
	$(eval install: $(DESTDIR)$(datadir)/schema/$(notdir $t)) \
	$(eval $(DESTDIR)$(datadir)/schema/$(notdir $t): $t))
