#!/usr/bin/perl -w

use strict;

my %hash;

while (<>) {
	chomp;
	$hash{"$_"}++;
}

for my $key (keys %hash) {
	print "$key\t$hash{$key}\n";
}