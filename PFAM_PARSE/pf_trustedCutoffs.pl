#!/usr/local/bin/perl -w 

$|=1;
$/="//";

while (<>) {
  @array = ();
  @array = split("\n", $_);
  for $line (@array) {
    if ($line =~ /^NAME  (.+)$/) {
      $name = $1;
    }
    if ($line =~ /^TC    (\-?\d+\.\d+) (\-?\d+\.\d+)$/) {
      $tc1 = $1;
      $tc2 = $2;
    }
  }
    print "$name\t$tc1\t$tc2\n";
}

