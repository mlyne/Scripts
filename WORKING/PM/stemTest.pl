#!/usr/bin/perl
use strict;
use warnings;
use Lingua::Stem::Snowball;

my $wordFile = $ARGV[0];

open(IFILE, "< $wordFile") || die "cannot open $wordFile: $!\n";

my @words;

@words = split(/\n/, <IFILE>);

#my @words = qw( horse hooves );

my $dict = Lingua::Stem::Snowball->new;
my @stems = $dict->stem(\@words);

print "STEMS: ", join(", ", @words), "\n";