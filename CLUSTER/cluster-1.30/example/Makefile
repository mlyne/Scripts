ifndef CC
CC=gcc
endif

OBJECTS = example.o cluster.o ranlib.o com.o linpack.o
SRCDIR = ../src
RANLIBDIR = ../ranlib

example.exe: $(OBJECTS)
	$(CC) -Wall $(OBJECTS) -o example.exe

example.o: example.c $(SRCDIR)/cluster.h
	$(CC) -c -Wall -I$(SRCDIR) example.c

cluster.o: $(SRCDIR)/cluster.c $(SRCDIR)/cluster.h $(RANLIBDIR)/src/ranlib.h
	$(CC) -c -Wall -I$(RANLIBDIR)/src $(SRCDIR)/cluster.c

ranlib.o: $(RANLIBDIR)/src/ranlib.c $(RANLIBDIR)/src/ranlib.h
	$(CC) -c -Wall $(RANLIBDIR)/src/ranlib.c

com.o: $(RANLIBDIR)/src/com.c $(RANLIBDIR)/src/ranlib.h
	$(CC) -c -Wall $(RANLIBDIR)/src/com.c

linpack.o: $(RANLIBDIR)/linpack/linpack.c
	$(CC) -c -Wall $(RANLIBDIR)/linpack/linpack.c

clean:
	rm -f example.exe example.o cluster.o ranlib.o com.o linpack.o
