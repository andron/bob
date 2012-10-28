# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Creates a dot-graph from either the requirements (REQUIRES) or from the
# linkage flags (LDFLAGS), i.e. the way the artifacts are linked.

# This will disable some check requirements macro.
$(if $(filter dotgraph%,$(MAKECMDGOALS)),\
	$(eval override check_requires :=))

help-plugin-dotgraph:
	@echo
	@echo " Dot graph generation                                                   "
	@echo "------------------------------------------------------------------------"
	@echo "  Generates a dot-graphs from either linkage or require information."
	@echo "  In build mode linkgraph creates a graph of link dependencies. In meta"
	@echo "  mode the target requiregraph creates a graph of all found projects"
	@echo "  requirements."
	@echo
	@echo "  Variables:"
	@echo
	@echo "  targets = <T>[,<T>]"
	@echo "      T = target,   Generate for a specific target."
	@echo "      T = group_<G> Generate for all targets in group G."
	@echo
	@echo "  groups = <G>[,<G>] | ALL"
	@echo "      Generate for a specific order of groups or for ALL."
	@echo "      No groups will be generated if empty or undefined."
	@echo
	@echo "  requires = <T>[,<T>]"
	@echo "      Generate for a specific source. I.e. where deps come from."
	@echo
	@echo "  dotfeatures"
	@echo "      A comma separated list of tokens which adds extra \"stuff\" to"
	@echo "      the graph. Currently takes: strip, noexternal"
	@echo
	@echo "  Examples:"
	@echo "      % make linkgraph"
	@echo "      % make linkgraph.png targets=foo"
	@echo "      % make requiregraph"
	@echo "      % make requiregraph groups=ALL"
	@echo "      % make requiregraph targets=group_bar groups=ALL"
	@echo


# Dotgraph generation
# ******************************************************************************
.PHONY: linkgraph requiregraph dotgraphdummy __remove_dot_and_ps_files __always__
dotgraphdummy:;

linkgraph requiregraph: $$@.ps $$@.png $$@.svg

linkgraph.dot: __always__
	@$(MAKE) -f Makefile -s dotgraphdummy \
	__bobENABLEDOTCODE=yes \
	__bobDISABLECHECKREQUIREMENTS=yes > $@

requiregraph.dot: __always__
	@$(MAKE) -f Makefile -s dotgraphdummy \
	__bobENABLEMETADOTCODE=yes \
	__bobDISABLECHECKREQUIREMENTS=yes > $@


# Add rule to distclean to remove dotfiles.
distclean: __remove_dot_and_ps_files
__remove_dot_and_ps_files:
	@-$(__bob.cmd.rm) linkgraph.* requiregraph.*


# From dot to some types of files, we will not support all that dot does.
%.ps %.svg %.png: %.dot
	@if [ -f $$(which dot) ]; then \
		dot -T$(patsubst .%,%,$(suffix $@)) -o $@ $<; \
		if [ -r $@ ]; then \
			echo "$(C_PREFIX) Created $@"; \
		else \
			echo "Error: Could not create $@, check $<"; \
		fi; \
	else \
		echo "Error: Program dot does not exists, cannot generate output.";	\
	fi

# Dot code macros
# ******************************************************************************

# Print the dot header and footer.
# 
# -
define dot_print_header
$(info strict digraph dependencies {)\
$(info compound=true)\
$(info graph [nodesep="0.10",rankdir=LR,ranksep="1.10",overlap="false",splines="true"];)\
$(info node [fontname="sans",fontsize="9"];)
endef

define dot_print_footer
$(info })
endef


# Generates temporary variables which are used by the dot_print_deps macro.
#
# $1: All targets to be considered
quote := " "
empty :=
space := $(empty) $(empty)
comma := $(space),$(space)
define dot_generate_deps_variables
$(foreach t,$1,\
	$(eval $t_dotintdeps := \
		$(subst $(space),$(quote),$(strip $(__bob_$t_internaldeps))))\
	$(eval $t_dotalldeps := \
		$(subst $(space),$(quote),$(strip $(__bob_$t_internaldeps) \
			$(if $(findstring noexternal,$(dotfeatures)),,$(__bob_$t_externaldeps)))))\
	$(eval __dotallintdeps := \
		$(sort $(__dotallintdeps) $($t_dotintdeps)))\
	$(eval __dotallextdeps := \
		$(sort $(__dotallextdeps) \
			$(if $(findstring noexternal,$(dotfeatures)),,$(__bob_$t_externaldeps)))))
endef

# Prints nodes and dependencies for a target list. Uses the second argument to
# select on of the dependency variants created by dot_generate_deps_variables.
#
# $1: All targets to be considered -- $2: Which deps type to use.
define dot_print_deps
$(foreach t,$(filter-out %plugin.so,$(filter-out lib%.a,$(filter-out lib%.so,$(sort $1)))), 	\
	$(info "$t" [label="$t",shape="box",style="filled",fillcolor="#4ac6ff",color="black"];)			\
	$(if $($t_$2),$(info "$t" -> { "$($t_$2)" } [style="solid",color="red"];)))									\
$(foreach t,$(filter %plugin.so,$(sort $1)),																									\
	$(info "$t" [label="$t",shape="egg",style="filled",fillcolor="#7bccff",color="black"];)			\
	$(if $($t_$2),$(info "$t" -> { "$($t_$2)" } [style="solid",color="black"];)))								\
$(foreach t,$(filter lib%.so,$(filter-out %plugin.so,$(sort $1))),														\
	$(info "$t" [label="$t",shape="ellipse",style="filled",fillcolor="#ff6070",color="black"];) \
	$(if $($t_$2),$(info "$t" -> { "$($t_$2)" } [style="solid",color="black"];)))								\
$(foreach t,$(filter %.a,$(sort $1)),																													\
	$(info "$t" [label="$t",shape="ellipse",style="filled",fillcolor="#b64550",color="black"];) \
	$(if $($t_$2),$(info "$t" -> { "$($t_$2)" } [style="solid",color="black"];)))
endef

# Use the internal dependencies.
#
# $1: All targets to be considered
define dot_print_deps_internal
$(call dot_print_deps,$1,dotintdeps)
endef

# Use all dependencies.
#
# $1: All targets to be considered
define dot_print_deps_full
$(call dot_print_deps,$1,dotalldeps)\
$(foreach lib,$(__dotallextdeps),\
	$(info "$(lib)" [style="filled",color="#d8ff0d"];))
endef

# $1: List of targets (nodes) -- $2: Variable name containing linked nodes (edges)
define dot_print_target_nodes
$(foreach n,$1,\
	$(if $(strip $($n$2)),$(eval __color__ := fadd33),$(eval __color__ := bbfa30)) \
	$(if $(findstring $n,$(_dotrequires)),$(eval __color__ := BB6095))\
	$(info "$n" [label="$n",shape=box,style=filled,fillcolor="#$(__color__)",color=black];))
endef

# $1: List of targets (nodes)
# $2: Variable name containing cluster names (subgraphs)
# $3: content in clusters
define dot_print_cluster_nodes
$(foreach g, $3, \
	$(info subgraph cluster_$g {) \
	$(foreach q, $(cluster_$g$2), \
		$(eval r := $(word 1,$(subst -,$(space),$q))) \
		$(if $(findstring $r, $1), \
			$(info $r[label="$r",shape=box,style=filled,fillcolor="#10bb10",color=black]), \
			$(info $r[label="$r",shape=box,style=filled,fillcolor="#fa5045",color=black]))) \
	$(info label="$g") \
	$(info }) \
)
endef

define dot_print_cluster_edges
$(foreach t, $1, \
	$(foreach q, $($t_REQUIRES), \
		$(eval r := $(word 1,$(subst -,$(space),$q))) \
		$(eval x := $(sort $(filter $(cluster_$($r_GROUP)_TARGETS), $($t_REQUIRES)))) \
		$(eval y := $(sort $(cluster_$($r_GROUP)_TARGETS))) \
		$(if $(findstring "$x","$y"), \
			$(if $($t_$($r_GROUP)_ARROW),, \
				$(info $t -> $r[lhead=cluster_$($r_GROUP)]) \
				$(eval $t_$($r_GROUP)_ARROW := defined)), \
			$(info $t -> $r[arrowhead=halfopen,href="\T",target="$r"]))))
endef

# $1: List of targets (nodes) -- $2: Variable name containing linked nodes (edges)
define dot_print_edges
$(foreach n,$(sort $1), \
	$(foreach e,$(sort $($n$2)), \
		$(eval f := $(word 1,$(subst -,$(space),$e))) \
		$(info $n -> $f [arrowhead=halfopen,href="\T",target="$f"]) \
		$(if $(filter $f,$1),, \
			$(info "$f" [label="$f",shape=box,style=filled,fillcolor="#fa5045",color=black];))))
endef
