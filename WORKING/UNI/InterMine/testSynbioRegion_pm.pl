#!/usr/bin/perl
#
#

use strict;
use warnings;

use SynbioRegionSearch qw/regionSearch/;
use SynbioFetchExpression qw/expressionResults/;

my $region = "NC_000913.3:2598423..2598460";
#my $organism = "E. coli str. K-12 substr. MG1655";

my ($org_short, $geneRef) = regionSearch($region);
my @genes = @$geneRef;

print $org_short, " ";

my @identifiers;
foreach my $gene (@genes) {
  my $symbol = $gene->[0];
  my $identifier = $gene->[1];
  push (@identifiers, $identifier);
  print "S: $symbol\tID: $identifier\n";
}

foreach my $gene (@identifiers) {

  my ($geneRef, $expressRef) = expressionResults($gene, $org_short);

  my @results = @$expressRef;
  #print "Here:", $results[-1], "\n";

  print $geneRef, "\tRESULTS:\n";

  for my $result (@results) {
    print join("\t", @{ $result }), "\n";
  }

}
