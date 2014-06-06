#!/usr/bin/perl -w

use strict;

while (<>)
{
  chomp;
  my @array = split("\t", $_);
  print "$array[-1]\n";
}
