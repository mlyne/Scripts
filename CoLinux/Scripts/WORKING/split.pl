#!/usr/bin/perl -w

use strict;

my @array;

while (<>) {
@array = split("\t", $_);

for my $i (0 .. $#array) {
	print "$array[$i]!\n";
}
print "\n";

}