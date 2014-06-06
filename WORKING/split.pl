#!/usr/bin/perl -w

use strict;
use warnings;
use TimeCheck;

my @array;

#Time_Check();

while (<>) {
  chomp;
  @array = split("\t", $_);

  for my $i (0 .. $#array) {
    print "$array[$i]!\n";
  }
  
  print "\n";
}