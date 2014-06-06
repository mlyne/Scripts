#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Std;
use CAM::PDF;
use CAM::PDF::PageText;

my $usage = "Usage:PDF2text.pl PDF_file1\n

Options:
\t-h\tThis help
\t-e\toptional switch\n";

unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts);

getopts('h', \%opts);
defined $opts{"h"} and die $usage;

my $inFile = $ARGV[0];

my $pdf = CAM::PDF->new($inFile);
my $pageone_tree = $pdf->getPageContentTree(1);
open TEST, ">", "test.txt" or die $!;
print TEST CAM::PDF::PageText->render($pageone_tree);
close TEST;
