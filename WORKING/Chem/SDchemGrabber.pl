#!/usr/bin/perl -w

# SDchemGrabber.pl

# pragmas
use strict;

################# USAGE ###############
# Usage
my $usage = "Usage: SDchemGrabber.pl [--help]

SDchemGrabber.pl drug_File SD_file out_file

\t--help   This list

Used for retrieving entries from a drug SD database
Searches performed with file of drug names

\n";

unless ( $ARGV[0] ) { die $usage }
########################################

$/ = undef;

# Take input from the command line
my $drug_file = $ARGV[0];
my $query_file = $ARGV[1];
my $out_file = $ARGV[2];

# Open Drug and Query files
open(DFILE, "< $drug_file") || die "cannot open $drug_file: $!\n";
open(QFILE, "< $query_file") || die "cannot open $query_file: $!\n";
open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";

my @foo;
my $drug;

READ_DRUG_LOOP:while (<DFILE>)
{
  chomp; # remove newlines

# Assign drug query
  $drug = $_;
}


READ_SD_FILE:while (<QFILE>) 
{
	my @entries = split(/\$\$\$\$\n/, $_);
	#print "######\n", @entries, "\n######\n";
	print $drug, "\n";
	
	@foo = grep(m/$drug/, @entries);
	print @foo;

}


# Close the file we've op
close(DFILE);
close(QFILE);
close(OUT_FILE);



