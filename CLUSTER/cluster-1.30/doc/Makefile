imagesrc = ../html/images
figures = $(wildcard $(imagesrc)/*.png)

all: imagedir cluster3.pdf cluster.pdf

imagedir:
	mkdir -p images

cluster3.pdf: cluster3.texinfo $(patsubst $(imagesrc)/%.png,images/%.eps,$(figures))
	tex cluster3.texinfo
	dvipdfm cluster3

cluster.pdf: cluster.texinfo
	tex cluster.texinfo
	dvipdfm cluster

$(patsubst $(imagesrc)/%.png,images/%.eps,$(figures)): images/%.eps: $(imagesrc)/%.png
	# png2eps $< > $@
	pngtopnm $< | pnmtops -noturn -dpi=96 > $@

distdir: cluster3.pdf cluster.pdf

clean:
	rm -rf *.dvi *.aux *.log *.tmp images \
	  *.fn *.ky *.pg *.tp *.vr *.cp *.toc *.pdf *.txt
