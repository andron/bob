# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


ifdef dotfeatures
$(eval _dotfeatures := $(sort $(subst $(comma),$(space),$(dotfeatures))))
endif

# Generate dot-code in stdout.
# **********************************************************************
ifdef __bobENABLEDOTCODE
ifdef targets
$(eval _dottargets := $(sort $(subst $(comma),$(space),$(targets))))
else
$(eval _dottargets := $(sort $(__bobLIST_TARGETS)))
endif
ifndef dottype
dottype := full
endif
$(call dot_generate_deps_variables,$(_dottargets))
ifdef __bobDOTNOHEADERS
$(call dot_print_deps_$(dottype),$(_dottargets))
else
$(info // ------------------------------------------------------------)
$(info // dot-code by BOB)
$(info // ------------------------------------------------------------)
$(call dot_print_header)
$(call dot_print_deps_$(dottype),$(_dottargets))
$(call dot_print_footer)
endif
endif

# Meta graph, or the require graph.
# **********************************************************************
ifdef __bobENABLEMETADOTCODE

ifdef targets
$(eval _dottargets := $(sort $(subst $(comma),$(space),$(targets))))
else
$(eval _dottargets := $(sort $(LIST_NAMES)))
endif

# Filter out those who only have deps to what is in dotsource
ifdef requires
$(eval _dotrequires := $(sort $(subst $(comma),$(space),$(requires))))
$(eval _dottargets2 :=)
$(foreach t,$(_dottargets),\
	$(if $(filter $(_dotrequires),$(subst -,$(space),$($t_REQUIRES))),\
		$(if $(findstring strip,$(_dotfeatures)),\
			$(eval $t_REQUIRES := $(filter $(_dotrequires),$(subst -,$(space),$($t_REQUIRES)))))\
		$(eval _dottargets2 += $t)))
_dottargets := $(_dottargets2) $(_dotrequires)
endif

$(info // ------------------------------------------------------------)
$(info // dot-code by BOB)
$(info // ------------------------------------------------------------)
$(call dot_print_header)
$(call dot_print_nodes,$(_dottargets),_REQUIRES)
$(call dot_print_edges,$(_dottargets),_REQUIRES)
$(call dot_print_footer)

endif
