#!/usr/bin/perl -w
#
#
#

use strict;
use warnings;

my ($id, $dom_count);
my %dom_hash = ();

while (<>)
{
  ($id, $dom_count) = split(/\s+/, $_);
#  print "$id, $dom_count\n";
  $dom_hash{$id} = $dom_count;
}

sub byvalue { $dom_hash{$a} <=> $dom_hash{$b} }

foreach my $id_keys (sort byvalue  keys %dom_hash) 
{
  print "$id_keys: $dom_hash{$id_keys}\n";
}

