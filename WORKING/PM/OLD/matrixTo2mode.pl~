#!/usr/bin/perl -w

use strict;
use warnings;
#use LWP;

my $usage = "Usage: matrixTo2mode.pl matrix_file out_file

Takes an assymmetric matrix and converts it to a
Bipartite matrix consiting of:
Row [tab] Column [tab] value
\n";

unless ( $ARGV[0] ) { die $usage }

my $file = $ARGV[0];
my $out_file = $ARGV[1];

open(FILE, "< $file") || die "cannot open $file: $!\n";
open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";

chomp (my @matrix = <FILE>);
my $info = shift(@matrix) if grep /\Q#/, @matrix;
my $headers = shift(@matrix);
my $colTerms = shift(@matrix);
my @headTerms = split("\t", $headers);

#print OUT_FILE $headers, "\n";
#print OUT_FILE $colTerms, "\n";

my $queryCount = 1;

for my $entry (@matrix)
{
	chomp $entry;
	my @data = split("\t", $entry);
	my $drug = shift(@data);
	my $rowTerm = shift(@data);
	
#	print OUT_FILE "1", "\t", $rowTerm, "\n";

	my $headcount = 2;
	
	for my $val (@data)
	{
	  my $sTerm = ($headTerms[$headcount]);
#	  my $sTerm = ($headTerms[$headcount]);
	  print OUT_FILE $drug, "\t", $sTerm, "\t", $val, "\n" if $val;
	  $headcount++;
	}

}

