## Process this file with automake to produce Makefile.in

DOCDIST = doc/*.pdf doc/*.texinfo doc/structure.eps doc/Makefile
WINDIST = windows/cluster.hhp windows/cluster.ico windows/cluster.iss \
  windows/gui.c windows/format.bmp windows/Makefile windows/resources.h \
  windows/resources.rc
MACDIST = mac/main.m mac/Controller.* mac/English.lproj mac/cluster.icns \
  mac/Cluster.xcode/project.pbxproj mac/Cluster.pmsp mac/Makefile
PYTHONDIST = setup.py python
PERLDIST = Makefile.PL perl/Artistic.txt perl/MANIFEST.perl \
  perl/Cluster.pm perl/Cluster.xs perl/Makefile.PL perl/typemap \
  src/Makefile.PL perl/t perl/examples
EXAMPLEDIST = example/example.c example/Makefile example/README


if MOTIF
TMPSUBDIRS = X11
else
TMPSUBDIRS = src
endif
SUBDIRS = $(TMPSUBDIRS)

EXTRA_DIST = $(WINDIST) $(MACDIST) $(PYTHONDIST) $(PERLDIST) $(DOCDIST) \
  $(EXAMPLEDIST) html data

