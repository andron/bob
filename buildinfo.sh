#!/bin/bash

# Collect some information about the environment which could be of interest
# when debugging a build or recreating a build environment.

echo | cat <<EOF
# Package: ${__name}-${__version}-${__release}
# Built:   By $USER on `hostname`
# Date:    `date`
# 
# BOBHOME: $BOBHOME
# 
# DEFINES: $DEFINES
# 
# Compiler and linker:
#    C:      `which ${CC}` ${CFLAGS}
#    C++:    `which ${CXX}` ${CXXFLAGS}
#    Linker: `which ${LD}` ${LDFLAGS}
# 
# Source the rest of this file to recreate the build environment!
# (Some variables have been filtered out)
#
EOF


# Check for changes if version control is Git.
echo | cat <<EOF


#
# Version control
#
# Git
EOF
git rev-parse --git-dir > /dev/null 2>&1
if [ $? -eq 0 ]; then
	git whatchanged -1 -- .
	echo
	echo "# Workspace changes ..."
	git diff --numstat
	echo "# ----------------------------------------------------------------------"
fi


# Print environment.
echo | cat <<EOF


#
# Environment
#
EOF
env | \
	sort | \
	egrep -v "^__|^SSH|^MAIL|^SHELL=|^DISPLAY=|^LS_COLORS=|^GNOME|^GDM|^DBUS_SESSION|^GPG"
