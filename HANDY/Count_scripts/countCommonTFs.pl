#!/usr/bin/perl -w
#
#

use strict;
use warnings;

my ($id, $tfs);
my %TFhash = ();

while (<>)
{
  ($id, $tfs) = split(/\t/, $_);
  $TFhash{$_}++ for split(/\s/, $tfs);

}

sub byvalue { $TFhash{$a} <=> $TFhash{$b} }

foreach my $id_keys (sort byvalue  keys %TFhash) 
{
  print "$id_keys: $TFhash{$id_keys}\n";
}

