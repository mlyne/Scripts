#!/usr/bin/perl

$count=1;

while (<>)
{
  chomp;
  print "$count\t $_\n";
  $count++;
}
