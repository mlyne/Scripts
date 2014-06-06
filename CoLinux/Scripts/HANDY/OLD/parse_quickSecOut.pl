#!/usr/local/bin/perl -w 

use strict;

my @array = ();
my $id = "";
my $count;

while (<>) {
  
  s/^\s*$//msg;
  s/^\n$//msg;

  my $count = "";
  @array = split("\t", $_);
  $id = $array[0];


  if (/SigP/) {
    $count++;
  }

  if (/TMAP/) {
    $count++;
  }

  if (/TMHMM/) {
    $count++;
  }

  if (/secreted/) {
    $count++;
  }

  print "$id\t$count\n";
}
