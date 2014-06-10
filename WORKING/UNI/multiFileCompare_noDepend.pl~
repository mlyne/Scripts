#!/usr/bin/perl

use strict;
use warnings;

my @sets;
my @files = (@ARGV);

print "ID";
for my $fname (@files) {
  print "\t", $fname;
}

print "\n";

for my $f (@files) {
  open(my $fh, '<', $f) or die;
  my $s = [];

  while (my $line = <$fh>) {
    push @$s, $_ unless grep {line eq $_} @$s;

  }

  close $fh;
  push @sets, $s;
}

my %h = map {($_ => 1)} map {@$_} @sets;

my @u = keys %h;

for my $item (@u) {
  print "$item: ";

  for my $index (0 .. $#files) {
    print "$file[$index](" . (grep {$item eq $_} @{$sets{$index}}) ? 'YES' : 'NO') .

  }
  print "\n";
}