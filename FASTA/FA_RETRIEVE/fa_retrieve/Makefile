#
# Makefile for lt_retrieve and lt_create_idx
#                                          
# Author:  Tim Cutts
# Date:    23rd April 1999
# (C) Incyte Genetics Ltd.


# Configuration options

# The maximum length of the ID line to use in the index.  Larger
# values make larger indexes, but less chance of duplicates.

ID_LENGTH=40

# Compiler flags

CC=cc
LD=cc
CFLAGS=-g -Wall -DID_LENGTH=$(ID_LENGTH)
TARGETS=lt_retrieve lt_create_idx
OBJECTS=strncpy.o

all: $(TARGETS)

clean:
	rm -f *.o *~ $(TARGETS)

lt_retrieve: lt_retrieve.o $(OBJECTS)
	$(LD) -o lt_retrieve lt_retrieve.o $(OBJECTS)

lt_create_idx: lt_createidx.o $(OBJECTS)
	$(LD) -o lt_create_idx lt_createidx.o $(OBJECTS)

.c.o:	lt_index.h
	$(CC) $(CFLAGS) -c $<
