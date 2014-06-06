#!/usr/local/bin/perl -w 
#
#
#

use strict;

$| = 1;

my @files = ();

@files = <*.data>;

for my $i (@files)
{
  open (FILE, "< $i") or die "Could not open $i: $!\n";

  my $adip_cnt = 0;
  my $count = 0;

  while (<FILE>)
  {
    chomp;
    if ($_ =~ /Adip/) 
    {
      $adip_cnt++;
    }
    $count++;
  }
  my $perc = ($adip_cnt / $count) * 100;
  print "$i\t$adip_cnt\t$count";
  printf "\t%.f\n", $perc;

  close(FILE) or die "Could not close $i: $!\n";
}


