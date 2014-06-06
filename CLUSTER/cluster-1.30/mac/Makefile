DOCDIR = ../doc
HTMLDIR = ../html

all: $(HTMLDIR)/index.html $(HTMLDIR)/html\ idx $(DOCDIR)/cluster3.pdf
	xcodebuild
	rm -r build/Cluster.build

$(HTMLDIR)/index.html: $(DOCDIR)/cluster3.texinfo
	$(MAKE) -C $(HTMLDIR)

html\ idx: $(HTMLDIR)/index.html
	# Has to be done by hand by dropping the html directory unto the
	# Apple Help Indexing Tool

$(DOCDIR)/cluster3.pdf: $(DOCDIR)/cluster3.texinfo
	$(MAKE) -C $(DOCDIR)

clean:
	rm -rf build
