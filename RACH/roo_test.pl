#!/usr/local/bin/perl -w

use strict;

my @line = ();
my @lol = ();

while (<>)
{
  chomp;
  @line = split(/\t/, $_);
  push @lol, [@line];
}

for my $i(0 .. $#lol)
{
  if ($lol[$i]->[5] =~ /NA/)
  {
    $lol[$i]->[3] = 'negative';
    $lol[$i]->[5] = '""';
  }
}

for my $entry(0 .. $#lol)
{
  print join("\t", @{$lol[$entry]}), "\n";
}
