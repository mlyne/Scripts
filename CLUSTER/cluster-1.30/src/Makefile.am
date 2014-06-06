## Process this file with automake to produce Makefile.in

SRC = command.c cluster.c cluster.h data.c data.h
RANLIB = ../ranlib/src/ranlib.c ../ranlib/src/ranlib.h ../ranlib/src/com.c
LINPACK = ../ranlib/linpack/linpack.c

bin_PROGRAMS = cluster

cluster_SOURCES = $(SRC) $(RANLIB) $(LINPACK)
AM_CPPFLAGS = -I../ranlib/src -DPREFIX=\"$(prefix)\"
