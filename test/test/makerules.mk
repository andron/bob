# -*- mode:makefile; tab-width:2; -*-

include $(HEADER)

TARGETS := test.tmp.foobar1 test.tmp.foobar2

_LINK := foppa

test.tmp.foobar1_SRCS := test.tmp.foobar1.cpp
test.tmp.foobar2_SRCS := test.tmp.foobar2.cpp

include $(FOOTER)
