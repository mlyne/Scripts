## Process this file with automake to produce Makefile.in

SRC = gui.c ../src/cluster.c ../src/cluster.h ../src/data.c ../src/data.h
RANLIB = ../ranlib/src/ranlib.c ../ranlib/src/ranlib.h ../ranlib/src/com.c
LINPACK = ../ranlib/linpack/linpack.c
HTML = ../html/*.html
IMAGE = ../html/images/*.png
FILEFORMAT = format.xpm
DOC = ../doc/cluster3.pdf

bin_PROGRAMS = cluster

htmldir = $(prefix)/cluster/html
imagedir = $(prefix)/cluster/html/images
docdir = $(prefix)/cluster/doc
fileformatdir = $(prefix)/cluster

html_DATA = $(HTML)
image_DATA = $(IMAGE)
doc_DATA = $(DOC)
fileformat_DATA = $(FILEFORMAT)

cluster_SOURCES = $(SRC) $(RANLIB) $(LINPACK)
cluster_LDFLAGS = $(X_LIBS) -lXm -lXt -lX11
AM_CPPFLAGS = -I../ranlib/src -I../src $(X_CFLAGS) -DPREFIX=\"$(prefix)\"

EXTRA_DIST = format.xpm
