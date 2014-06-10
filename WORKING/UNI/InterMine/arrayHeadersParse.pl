#!/usr/bin/perl

# every perl script should start with these two lines.
use strict;
use warnings;

my $header = "//TITLE	The condition-dependent transcriptome of Bacillus subtilis 168
//GEO_ACC	GSE27219
//PMID	22383849
//SUMMARY	Recent studies revealed the unsuspected complexity of the bacterial transcriptome but its systematic analysis across many diverse conditions remains a challenge. Here we report the condition-dependent transcriptome of the prototype strain B. subtilis 168 across 104 conditions reflecting the bacterium's life-styles. This data set composed of 269 tiling array hybridizations allowed to observe ~85% of the annotated CDSs expressed in the higher 30% in at least one hybridization and thus provide an excellent coverage of the transcriptome of this bacterium. In addition to the Genbank annotation 1583 new segments of the chromosome were identified as transcribed and have transcription levels reported in the data matrix. RNA samples prepared from B. subtilis 168 grown under 104 experimental conditions were reverse transcribed, labeled and hybridized to tiling arrays. Most hybridizations were performed in duplicate or triplicate using RNA isolated from independent cultures. All experiments were performed
with strain BSB1 which is a tryptophan-prototrophic (trp+) derivative of the 168 trpC2 strain.
//PROTOCOL	10 µg of RNA were converted into Cy3-labeled cDNA by Roche NimbleGen (Madison, WI, USA) using the BaSysBio protocol for strand-specific hybridization (Rasmussen et al., 20
09). Hybridization and Scanning were performed by Roche NimbleGen (Madison, WI USA) following their standard operating protocol. See www.nimblegen.com. An aggregated expression value was compu
ted for each Genbank annotated CDS and newly defined transcribed region as the median log2 expression signal intensity of probes lying entirely within the corresponding region. The expres
sion intensity was computed from the raw intensity data using a model of signal shift and drift and correcting for probe affinity variations as described in (Nicolas et al., 2009, Bioinfo
rmatics 25, 2341-2347) To control for possible cross-hybridization artefacts the sequence of each probe was BLAST-aligned against the whole chromosome sequence and probes with a SeqS valu
e above the 1.5 cut-off were discarded (Wei et al., 2008 Nucl. Acids Res. 36, 2926-2938).
//IM_METHOD	This is what we did. It was great!
";

my @lines = split("\n", $header);

my ($title, $geo_accession, $pmid, $description, $protocol);

foreach my $line (@lines) {

  if ($line =~ /TITLE\t(.+)/) {
    $title = $1;
    print "TIT: ", $title, "\n";
    next;
  }

  if ($line =~ /GEO_ACC\t(.+)/) {
    $geo_accession = $1;
    print "GAcc: ", $geo_accession, "\n";
    next;
  }

  if ($line =~ /PMID\t(.+)/) {
    $pmid = $1;
    print "PMID: ", $pmid, "\n";
    next;
  }

  if ($line =~ /SUMMARY\t(.+)/) {
    $description = $1;
    print "DESC: ", $description, "\n";
    next;
  }

  if ($line =~ /PROTOCOL\t(.+)/) {
    $description .= "\n" . "$1";
    print "DESC: ", $description, "\n";
    next;
  }

  if ($line =~ /IM_METHOD\t(.+)/) {
    $description .= "\n" . "$1";
    print "DESC: ", $description, "\n";
    next;
  }
}