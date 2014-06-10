#!/usr/bin/perl

use strict;
use warnings;

my %data = <<END =~ /(\w+)\t(.*)/g;

AR      DNA microarray and macroarray
CH      Chromatin immunoprecipitation microarray (ChIP-on-chip)
DB      Disruption of Binding Factor gene
DP      Deletion assay
FT      Footprinting assay (DNase I, DMS, etc.)
FP      Fluorecent protein
GS      Gel retardation assay
HB      Slot blot analysis
HM      Homology search
OV      Overexpression of Binding Factor gene
PE      Primer extension analysis
RG      Reporter gene (e.g., lacZ assay)
RO      Run-off transcription assay
ROMA    Run-off transcription followed by macroarray analysis
S1      S1 mapping analysis (S1 nuclease transcript mapping)
SDM     Site-directed mutagenesis (Oligonucleotide-directed mutagenesis)
ND      No Data
END

foreach my $key (keys %data) {
  say $key, " : ", $data{$key};
}

