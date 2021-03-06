#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Std;

my $usage = "Usage:termReFreq.pl termMesh_file\n

Options:
\t-h\tThis help
\t-e\tenriched count (count / weight)\n";

unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts);

getopts('h', \%opts);
defined $opts{"h"} and die $usage;

my $inFile = $ARGV[0];

open(IN_FILE, "< $inFile")  || die "cannot open $inFile: $!";

while (<IN_FILE>)
{
    chomp;
    my ($weight, $count, $term) = split(/\t/, $_);
    my $enrichCount = (sprintf "%.2f", ($count/$weight));
    print $enrichCount, "\t", $term, "\n";

} # WHILE block

close(IN_FILE);