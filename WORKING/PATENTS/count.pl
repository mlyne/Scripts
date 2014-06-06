#!/usr/bin/perl

use strict;
use warnings;

my $hitCount = $ARGV[0];

  if ($hitCount <= 100) {
    my $range = "1-$hitCount";
    print  "range: $range\n";
  } else {
    
    my $start = 1;
    my $end = 100;
    
    print "range: ", $start,  "-", $end, "\n";

    while (($end + 100) < $hitCount) {
      $start = ($end +1);
      $end = ($start + 99);
      
      print "range: ", $start,  "-", $end, "\n";
    }
    
    $start = ($end +1);
    $end = $hitCount;
    print "range: ", $start, "-", $end, "\n";
    
}
