#!/usr/bin/perl -w
#
#

use strict;
use warnings;

my ($id, $tfs);
my %TFhash;

while (<>)
{
  %TFhash = ();
  chomp;
  ($id, $tfs) = split(/\t/, $_);
  $TFhash{$_}++ for split(/\s/, $tfs);
  print $id, ":\t";

  foreach my $id_keys (sort byvalue keys %TFhash) 
  {
    print "$id_keys($TFhash{$id_keys}), ";
  }

  print "\n";
}

sub byvalue { $TFhash{$b} <=> $TFhash{$a} }



