#!/usr/local/bin/perl -w
#
#
#

use strict;

my ($locus, $gene_cds, $alt_cds);
my %locus_hash;

 READ_LOOP: while (<>)
{
  ($locus, $gene_cds, $alt_cds) = split(/\t/, $_);

  $locus_hash{$locus}->{$gene_cds}->{$alt_cds} = undef;

}

my ($hrLocus, $cds, $hrCDS);

foreach $locus (sort keys %locus_hash) {
  $hrLocus = $locus_hash{$locus};
  while (($cds, $hrCDS) = each (%$hrLocus)) {
    print "Locus:$locus\tCDS:$cds\t";
    print "Alt:";
    print join(', ', keys %$hrCDS);
    print "\n";
  }
}

