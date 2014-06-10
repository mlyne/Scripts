#!/usr/bin/perl

use strict;
use warnings;
use Set::Scalar;
use List::Util qw/reduce/;

my @sets;
my @files = (@ARGV);

print "ID";
for my $fname (@files) {
  print "\t", $fname;
}

print "\n";

for my $f (@files) {
        open(my $fh, '<', $f) or die;
        my $s = Set::Scalar->new;
        while (<$fh>) {
	  chomp;
          $s->insert($_) if $_;
        }
        close $fh;
        push @sets, $s;
}

my $u = reduce { $a + $b } @sets;

for my $item ($u->members) {
        print "$item";
        for my $index (0 .. $#files) {
#                print "$files[$index] (" . (($sets[$index]->has($item)) ? 'YES' : 'NO') . ')';
	  print "\t", (($sets[$index]->has($item)) ? 'YES' : 'NO');
        }
        print "\n";
        }


