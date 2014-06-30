#!/usr/bin/perl -w

use strict;
use warnings;

my $number = 1024;
#my $base = 2;

my $log2 = &log_base2($number);

print $log2, "\n";


sub log_base2 {
  my $value = shift;
  my $base = 2;
  
  my $logVal = log($value);
  my $logBase = log($base);

  print "$value, $base, $logVal, $logBase\n";

  return log($value)/log($base);
}