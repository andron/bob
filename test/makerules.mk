# -*- mode:make; tab-width:2; -*-

include $(HEADER)

# ----------------------------------------
NAME     := bobtests
VERSION  := 1.0.0
RELEASE  := 1
REQUIRES := # Nothing
$(call setup)
# ----------------------------------------

TARGETS := foobar libfoppa.so

foobar_SRCS := src/foobar.cpp
foobar_LINK := foppa
foobar_LDFLAGS := -Wl,-rpath,$(TGTDIR)

libfoppa.so_SRCS := src/foppa1.cpp src/foppa2.cpp

include $(FOOTER)
