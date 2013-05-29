# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# *** XSD VARIABLES ***
XSDCXX ?= $(firstword $(wildcard $(shell type -p xsd) $(shell type -p xsdcxx)))

# *** XSD MACROS ***
# Create headers according to transformation rules.
#
# $1: Schema filename
define __bob_xsd_header_name
$(addprefix $(_OBJDIR),$(patsubst %.xsd,%.xsd.h,$1))
endef
# Create source files according to transformation rules.
#
# $1: Schema filename
define __bob_xsd_object_name
$(addprefix $(_OBJDIR),$(patsubst %.xsd,%.xsd.o,$1))
endef

# *** XSD RULES ***
$(OBJDIR)/%.xsd.h $(OBJDIR)/%.xsd.cpp:%.xsd $$(@D)/.stamp
	@echo "$(C_PREFIX) [$(dir $<))] Generating $(@F)"
	$(XSDCXX) cxx-tree $(__target.xsdflags) \
	--hxx-suffix .xsd.h --cxx-suffix .xsd.cpp --output-dir $(dir $@) $<

# *** SCHEMA INSTALL RULES ***
# Dependencies are setup in the footer-file.
$(DESTDIR)$(datadir)/schema/%.xsd:
	$(call pretty_print_installation)
	@$(INSTALL_DATA) $< $@

# Add license text by using these options in a nifty way.
#
# 	--cxx-prologue ...
# 	--hxx-prologue ...

.PHONY: help-plugin-xsd
help-plugin-xsd:
	@echo -e \
	"\n XSD schema generated source files                                      " \
	"\n------------------------------------------------------------------------" \
	"\n  To add a schema to a target assign <T>_XSD_SRCS. All schemas must"      \
	"\n  reside in directory 'schema' in the targets module directory. The"      \
	"\n  generated files are put in the corresponding directory below obj and"   \
	"\n  are named <schema_name>.xsd.h and <schema_name>.xsd.cpp."               \
	"\n"                                                                         \
	"\n  The generated header file must be included as:"                         \
	"\n  #include \"schema/<schema_name>.xsd.h\""                                \
	"\n"                                                                         \
	"\n  Flags to xsd are added per target via <T>_XSDFLAGS, and via _XSDFLAGS"  \
	"\n  for all targets in the current $(RULES)."                               \
	"\n"
