OPTIONS = -DWINDOWS -DCALL=STDCALL
SRCDIR = ../src
RANLIBDIR = ../ranlib/src
LINPACKDIR = ../ranlib/linpack
DOCDIR = ../doc
HTMLDIR = ../html

all: cluster.exe clust95.exe cluster.chm $(DOCDIR)/cluster3.pdf

cluster.exe: gui.o resources.o data.o cluster.dll
	gcc -Wall -mwindows -mno-cygwin -O4 gui.o resources.o data.o \
	  -L. -lcluster -o cluster.exe

clust95.exe: gui95.o resources.o data.o cluster.dll
	gcc -Wall -mwindows -mno-cygwin -O4 gui95.o resources.o data.o \
	  -L. -lcluster -o clust95.exe

gui.o: gui.c
	gcc -mno-cygwin -mwindows -Wall -fno-strict-aliasing -c -O4 \
	  $(OPTIONS) -DUNICODE -I$(SRCDIR) gui.c

gui95.o: gui.c
	gcc -mno-cygwin -mwindows -Wall -fno-strict-aliasing -c -O4 \
	  $(OPTIONS) -I$(SRCDIR) gui.c -o gui95.o

resources.o: resources.rc
	windres -i resources.rc -o resources.o

data.o: $(SRCDIR)/data.c
	gcc -mno-cygwin -mwindows -Wall -c -O4 $(OPTIONS) $(SRCDIR)/data.c

cluster.dll: cluster.o libranlib.a liblinpack.a
	gcc -Wall -O4 -shared -o cluster.dll -Wl,--export-all-symbols \
	  -L. -lranlib -llinpack -mno-cygwin cluster.o

cluster.o: $(SRCDIR)/cluster.c
	gcc -c -O4 -Wall -I$(RANLIBDIR) $(OPTIONS) $(SRCDIR)/cluster.c

libranlib.a:
	gcc -c -O4 -Wall -mno-cygwin $(RANLIBDIR)/ranlib.c
	gcc -c -O4 -Wall -mno-cygwin $(RANLIBDIR)/com.c
	ld -r -O4 -o libranlib.a ranlib.o com.o

liblinpack.a:
	gcc -c -O4 -Wall -mno-cygwin $(LINPACKDIR)/linpack.c
	ld -r -O4 -o liblinpack.a linpack.o

clustersetup.exe: cluster.dll cluster.exe $(DOCDIR)/cluster3.pdf cluster.chm \
	  cluster.iss
	strip cluster.exe
	strip cluster.dll
	iscc cluster.iss

$(HTMLDIR)/index.html: $(DOCDIR)/cluster3.texinfo
	$(MAKE) -C $(HTMLDIR)

cluster.chm: cluster.hhp $(HTMLDIR)/index.html
	mv cluster.hhp $(HTMLDIR)
	cd $(HTMLDIR)
	-hhc $(HTMLDIR)/cluster.hhp
	mv $(HTMLDIR)/cluster.chm $(HTMLDIR)/cluster.hhp ../windows
	rm $(HTMLDIR)/toc.hhc
	cd ../windows

$(DOCDIR)/cluster3.pdf: $(DOCDIR)/cluster3.texinfo
	$(MAKE) -C $(DOCDIR)

clean:
	rm -f *.o *.a *.dll *.exe *.chm *.hhc
