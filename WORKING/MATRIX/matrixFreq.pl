#!/usr/bin/perl -w

use strict;

my $file = $ARGV[0];
open(FILE, "< $file") || die "cannot open $file: $!\n";

chomp (my @matrix = <FILE>);
my $date = shift(@matrix);
my $headers = shift(@matrix);
my $terms = shift(@matrix);

for my $entry (@matrix)
{
  chomp $entry;

  my @array = split("\t", $entry);
  my $drug = shift(@array);
  splice(@array, 0, 1);
  
#  my $allHits = shift(@array); # used with drg vs. all J. hits 
  my $count = "0";
  for my $val (@array) { $count += "$val" }
  print $count, "\t", $drug, "\n";
}
