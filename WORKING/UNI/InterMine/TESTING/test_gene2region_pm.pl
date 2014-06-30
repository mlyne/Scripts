#!/usr/bin/perl
#
#

use strict;
use warnings;

use SynbioGene2Location qw/geneLocation/;

my $identifier = shift;
my $org_short = "B. subtilis subsp. subtilis str. 168";

my ($geneRef) = geneLocation($org_short, $identifier);
my @gene_lookups = @$geneRef;

for my $result (@gene_lookups) {
   print join("\t", @{ $result }), "\n";
}

