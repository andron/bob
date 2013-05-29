# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Grab each target and check if they have an _XSD_SRCS. If so setup some
# dependencies. There is a pattern target which will generate the cpp and
# header file because of this dependency.

$(foreach t,$(TARGETS),\
	$(foreach x,$($t_XSD_SRCS),\
		$(if $(filter-out schema/%,$x),\
			$(info $(W_PREFIX) Schema files shall reside in directory 'schema': $x) \
			$(error Missplaced schema file)) \
		$(if $(findstring $(notdir $x),$(notdir $(__bob_xsd_allschemas))), \
			$(info $(W_PREFIX) Duplicate schema file found: $x) \
			$(error Duplicate schema file), \
			$(eval __bob_xsd_allschemas += $(_SRCDIR)$x)) \
		$(eval __bob_xsd_h := $(call __bob_xsd_header_name,$x)) \
		$(eval __bob_xsd_o := $(call __bob_xsd_object_name,$x)) \
		$(eval __bob_xsd_$t_headers += $(__bob_xsd_h)) \
		$(eval __bob_xsd_alltargets += $t) \
		$(eval $(__bob_xsd_h) : $(_SRCDIR)$x) \
		$(eval $(__bob_xsd_o) : $(__bob_xsd_h)) \
		$(eval $t_INCL += $(_I)$(_OBJDIR)) \
		$(eval $(TGTDIR)/$t : $(__bob_xsd_h) $(__bob_xsd_o)) \
		$(eval $(TGTDIR)/$t : __target.xsdflags := $($t_XSDFLAGS) $(_XSDFLAGS))))

# Clear the global xsd flags variable. We justed used it and the next time we
# will see it it will be either empty again or have a value but then it must
# have been set by the user.
_XSDFLAGS :=
