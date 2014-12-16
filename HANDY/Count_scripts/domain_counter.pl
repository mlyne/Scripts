#!/usr/bin/perl -w
#
# takes output from estpfam_parse.pl & 
# hmmpfam_parse.pl and counts the number
# of domains for each hit

use strict;
use warnings;

my ($id);

while (<>)
{
  my @array = split(/\s+/, $_);
  $id = $array[0];

  print "$id ", $#array, "\n";

}
