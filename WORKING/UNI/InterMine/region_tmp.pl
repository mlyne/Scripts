#!/usr/bin/perl
#
#

use strict;
use warnings;

use SynbioRegionSearch qw/regionSearch/;

my $region = shift;
#my $organism = "E. coli str. K-12 substr. MG1655";

my ($org_short, $geneRef) = regionSearch($region);
my @genes = @$geneRef;

print $org_short, " ";

foreach my $gene (@genes) {
  my $symbol = $gene->[0];
  my $identifier = $gene->[1];
  print "S: $symbol\tID: $identifier\n";
}

