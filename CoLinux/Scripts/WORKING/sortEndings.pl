#!/usr/bin/perl -w

use strict;

my @array;

while (<>) {
	chomp;
	my $rev_name = reverse $_;
	push(@array, $rev_name);
}

my @sorted = sort(@array);

#@array = split("\t", $_);

for my $i (0 .. $#sorted) {
	my $name = reverse $sorted[$i];
	print $name,"\n";
}
print "\n";
