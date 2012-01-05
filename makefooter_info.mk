# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Map information to project specific variables.
$(NAME)_VERSION  := $(VERSION)
$(NAME)_RELEASE  := $(RELEASE)
$(NAME)_REQUIRES := $(REQUIRES)
ifeq "$(GROUP)" ""
	$(NAME)_GROUP := other
else
	$(NAME)_GROUP := $(GROUP)
endif
$(NAME)_DIRECTORY := $(_MODULE)

# The feature level name, i.e. nameXY is very usefull for mapping targets to
# each other in the main file. The directory is necessary as well.
$(NAME)_FEATNAME := $(strip $(call __get_compactFname,$(NAME)-$(VERSION)))
$($(NAME)_FEATNAME)_DIRECTORY := $(_MODULE)

# Prefix is used for different purposes. For example, in meta build mode we want
# all projects to be installed into its own directory, but when the user
# supplies a prefix installation shall occur into that directory without any sub
# directories. !!OBS!! In Makefile we do a override assignment on prefix if the
# user has supplied it. Bob only assigns prefix as an ordinary variable, giving
# it a origin = "file".
ifeq "$(origin prefix)" "override"
$($(NAME)_FEATNAME)_PREFIX := $(prefix)
else
$($(NAME)_FEATNAME)_PREFIX := $(prefix)/$(NAME)
endif

# Create the uppercase name of the project and create the home and corresponding
# incl and libs variables. Exporting these shall provide them to the rest of the
# build.
UCNAME := $(call __uc,$(NAME))
export $(UCNAME)_HOME := $($($(NAME)_FEATNAME)_PREFIX)
export MAKEOVERRIDES  := $(sort $(MAKEOVERRIDES) $(UCNAME)_HOME=$($(UCNAME)_HOME))

# Map the module name to different target for this project. This makes it
# possible to type "make <directory>.[foo]" which feels (should feel) very
# intuitive.
# % make <directory>
# % make <directory>.install
# % make <directory>.test
# ... etc
$(_MODULE):           build_$($(NAME)_FEATNAME)
$(_MODULE).install:   install_$($(NAME)_FEATNAME)
$(_MODULE).software-install: software-install_$($(NAME)_FEATNAME)
$(_MODULE).clean:     clean_$($(NAME)_FEATNAME)
$(_MODULE).distclean: distclean_$($(NAME)_FEATNAME)

$(_MODULE).test:      test_$($(NAME)_FEATNAME)
$(_MODULE).test.tmp:  test.tmp_$($(NAME)_FEATNAME)
$(_MODULE).test.tdd:  test.tdd_$($(NAME)_FEATNAME)
$(_MODULE).test.reg:  test.reg_$($(NAME)_FEATNAME)
$(_MODULE).test.mod:  test.mod_$($(NAME)_FEATNAME)

$(_MODULE).check:     check_$($(NAME)_FEATNAME)
$(_MODULE).check.tmp: check.tmp_$($(NAME)_FEATNAME)
$(_MODULE).check.tdd: check.tdd_$($(NAME)_FEATNAME)
$(_MODULE).check.reg: check.reg_$($(NAME)_FEATNAME)
$(_MODULE).check.mod: check.mod_$($(NAME)_FEATNAME)

.PHONY:                         \
	all_$($(NAME)_FEATNAME)       \
	build_$($(NAME)_FEATNAME)     \
	install_$($(NAME)_FEATNAME)   \
	clean_$($(NAME)_FEATNAME)     \
	distclean_$($(NAME)_FEATNAME) \
	cppcheck_$($(NAME)_FEATNAME)

ifdef __bob_have_feature_cppcheck
$(_MODULE).cppcheck: cppcheck_$($(NAME)_FEATNAME)
endif

ifdef __bob_have_feature_rpm
$(_MODULE).rpm: rpm_$($(NAME)_FEATNAME)
endif

# Create lists for both name and featname for mapping the above variables.  The
# lists are not used for footer processing, only for later processing to find
# all available projects and stuff.
LIST_NAMES     := $(strip $(LIST_NAMES) $(NAME))
LIST_FEATNAMES := $(strip $(LIST_FEATNAMES) $($(NAME)_FEATNAME))
