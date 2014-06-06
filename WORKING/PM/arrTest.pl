#!/usr/bin/perl
use strict;
use warnings;

my @termSet = ("nucleotide polymorphisms", "immune response", "haplotype tagging", "disease", "gene", "polymorphisms", "receptor", "haplotype", "genes", "single nucleotide polymorphisms", "nucleotide", "cohort", "immune", "response", "central", "tagging", "receptors", "inflammatory", "colonic", "cohorts", "diseases", "inflammatory disease");

@termSet = sort {length $a <=> length $b} @termSet;

print "START: ", join(", ", @termSet), "\n";

print "\n";

my @noDup;

while (scalar(@termSet) > 0)
{
  my $testTerm = shift(@termSet);
  
  push(@noDup, $testTerm) unless grep {/\b\Q$testTerm\E\b/ } @termSet;
  
}

print "NO DUP: ", join(", ", @noDup), "\n";
