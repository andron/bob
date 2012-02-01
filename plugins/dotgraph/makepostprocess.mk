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
$(sort, \
$(eval n_targets := $(subst $(comma),$(space),$(targets))) \
$(foreach t, $(n_targets), \
	$(if $(findstring group_,$t), \
		$(eval y = $(subst group_,,$t)) \
		$(foreach p,$(LIST_NAMES), \
			$(if $(findstring "__$($p_GROUP)__","__$y__"), \
				$(eval _dottargets += $p),)), \
		$(eval _dottargets += $t))))
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

ifdef groups
$(eval _groups := $(subst $(comma),$(space),$(groups)))
endif

ifdef _groups
_dotgroups :=
$(foreach target, $(_dottargets), \
	$(eval cluster_$($(target)_GROUP)_TARGETS += $(target)) \
	$(eval _dotgroups += $($(target)_GROUP)) \
	$(foreach r, $($(target)_REQUIRES), \
		$(eval required_target := $(word 1,$(subst -,$(space),$r))) \
		$(eval $(required_target)_GROUP ?= external) \
		$(eval _dotgroups += $($(required_target)_GROUP)) \
		$(eval cluster_$($(required_target)_GROUP)_TARGETS += $(required_target)))) \
$(eval _dotgroups := $(sort $(_dotgroups)))
$(eval _dotgroups := $(_groups) $(_dotgroups))
endif


$(info // ------------------------------------------------------------)
$(info // dot-code by BOB)
$(info // ------------------------------------------------------------)
$(call dot_print_header)
ifdef groups
  $(call dot_print_cluster_nodes,$(_dottargets),_TARGETS, $(_dotgroups)) \
  $(call dot_print_cluster_edges,$(_dottargets),_TARGETS, $(_dotgroups))
else
  $(call dot_print_target_nodes,$(_dottargets),_REQUIRES)
  $(call dot_print_edges,$(_dottargets),_REQUIRES)
endif
$(call dot_print_footer)
endif
