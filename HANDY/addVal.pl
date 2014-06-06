#!/usr/bin/perl -w
# add vals - Works with domain list but adds numerical values

use strict;

my ($cat_id, $vals, $sum);

 READ_LOOP: while (<>)
{
	chomp;
  ($cat_id, $vals) = split(/\t/, $_);
#   print $cat_id, $vals, "\n";
  
  my @sumar = split(/ /, $vals);
  
  my $sum = 0;
	
  foreach my $var (@sumar) {
	  $sum += $var;
	  }
	  print $cat_id, "\t", $sum, "\n";

}