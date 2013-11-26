# -*- mode:makefile; tab-width:2; -*-

include $(HEADER)

# ----------------------------------------
NAME     := bobtests
VERSION  := 1.0.0
RELEASE  := 1
REQUIRES := # Nothing
$(call setup)
# ----------------------------------------

TARGETS := foobar libfoppa.so qt4app

_CXXFLAGS := -std=c++11 -pedantic
_LDFLAGS  := -Wl,-rpath,$(TGTDIR)

# Executable foobar, links with library foppa
foobar_SRCS := src/foobar.cpp
foobar_LINK := foppa

# Library foppa
libfoppa.so_SRCS := src/foppa1.cpp src/foppa2.cpp

# Qt4 Application
qt4app_SRCS     := src/qt4app*.cpp
qt4app_SRCS_MOC := src/qt4app*.hh
qt4app_SRCS_FRM := ui4/*.ui
qt4app_INCL     := -I/usr/include/qt4
qt4app_LINK     := QtCore QtGui

include $(FOOTER)
