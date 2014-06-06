#!/usr/bin/perl -w
#
#

use strict;
use warnings;

my ($cnt, $id);
my %authHash;

while (<>)
{
#  %authHash = ();
  chomp;
  ($cnt, $id) = split(/\t/, $_);
  $authHash{$id} = $cnt;

#  print $id, ":\t";
#  print "\n";
}

my $keyCnt = scalar(keys (%authHash) );

my $total;
while ( my ($key, $val) = each %authHash ) {
    $total += $val;
}

my $meanCnt = ($total / $keyCnt);
my $cutoff = $meanCnt;

$cutoff = 0.1 if ($meanCnt < 2);

print "$total $keyCnt $cutoff\n";

foreach my $authKey (sort byvalue keys %authHash) 
{
  print $authHash{$authKey}, "\t", $authKey, "\n" if ($authHash{$authKey} > $cutoff);
#  print $authHash{$authKey}, "\t", $authKey, "\n";
}

sub byvalue { $authHash{$b} <=> $authHash{$a} }