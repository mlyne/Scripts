#!/usr/bin/perl

use strict;
use warnings;

my $file = $ARGV)[1];

open(my $fh, '<', $file) or die;

while (<$fh>) {
  chomp;
  my @values = split('\t', $fh);
}
        
close $fh;


