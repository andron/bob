# -*- mode:makefile; tab-width:2; -*-

# Copyright (C) 2011, 2012, 2013, Saab AB
# All rights reserved.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


# Purely common macros/functions/programs (whatever the name is)

# Upper/lowercase translation
# ******************************************************************************
_lowercase := a b c d e f g h i j k l m n o p q r s t u v w x y z
_uppercase := A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
_indices   := 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26

define __translate
$(eval m := $3)\
$(foreach i,$(join $(addsuffix :,$1),$2),\
	$(eval pair := $(subst :, ,$i))\
	$(eval m := $(strip $(subst $(word 1,$(pair)),$(word 2,$(pair)),$m)))) $m
endef

# Uppercase a string
# $1: String to uppercase
define __uc
$(strip $(call __translate,$(_lowercase),$(_uppercase),$1))
endef

# Lowercase a string
# $1: String to lowercase
define __lc
$(strip $(call __translate,$(_uppercase),$(_lowercase),$1))
endef

# Special type of sorting
define __numtrans
$(eval m := $3)\
$(foreach i,$(join $1,$(addprefix :,$2)),\
	$(eval m := $(patsubst $(word 1,$(subst :, ,$i))%,$(word 2,$(subst :, ,$i))%,$m)))$m
endef

_sortnum := 0 1 2 3 4 5 6 7 8 9
_sortalp := A B C D E F G H I J
define sortn
$(eval pop :=)\
$(eval tmp := $(call __numtrans,$(_sortnum),$(_sortalp),$1))\
$(foreach i,$(join $(_sortnum),$(addprefix :,$(_sortalp))),\
	$(eval pop := $(pop) $(filter %$(word 1,$(subst :, ,$i)),$(tmp))))\
$(eval tmp := $(sort $(filter-out $(pop),$(tmp))) $(sort $(pop)))\
$(strip $(call __numtrans,$(_sortalp),$(_sortnum),$(tmp)))
endef


# Version string handling.
# Handle string on the form foo-x.y.z in different ways.
# ******************************************************************************

#
# Compact format down to api level.
#
# $1: Version string
define __get_compactAname
$(eval tmp := $(subst -, ,$(subst ., ,$1))) \
$(subst $(space),,$(wordlist 1,2,$(tmp)))
endef

#
# Compact format down to feature level.
#
# $1: Version string
define __get_compactFname
$(eval tmp := $(subst -, ,$(subst ., ,$1))) \
$(if $(word 2,$(tmp)),$(if $(word 3,$(tmp)),,$(eval tmp += 0))) \
$(subst $(space),,$(wordlist 1,3,$(tmp)))
endef

#
# Get name from a NVR-tuple (foo-1.2.3-1).
define __get_name
$(eval tmp := $(word 1,$(subst -, ,$(subst ., ,$1)))) $(if $(tmp),$(tmp),none)
endef

#
# Get version from a NVR-tuple.
define __get_version
$(eval tmp := $(word 2,$(subst -, ,$1))) $(if $(tmp),$(tmp),none)
endef

#
# Get api-level from a NVR-tuple.
define __get_api
$(eval tmp := $(word 1,$(subst ., ,$(call __get_version,$1)))) $(if $(tmp),$(tmp),0)
endef

#
# Get feature-level from a NVR-tuple.
define __get_feature
$(eval tmp := $(word 2,$(subst ., ,$(call __get_version,$1)))) $(if $(tmp),$(tmp),0)
endef

#
# Get patch-level from a NVR-tuple.
define __get_feature
$(eval tmp := $(word 3,$(subst ., ,$(call __get_version,$1)))) $(if $(tmp),$(tmp),0)
endef

#
# Get name-version string from _VERSION-variable.
define __get_available_name_version
$(eval tmp := $(call __get_name,$1)-$($(strip $(call __get_name,$1))_VERSION)) \
$(if $(tmp),$(tmp),none)
endef
# ******************************************************************************
