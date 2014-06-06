#!/usr/bin/perl -w

use LWP;
use strict;
#use Getopt::Long;
use Spreadsheet::WriteExcel;

# Take input from the command line
my $drug_file = $ARGV[0];
my $excel_file = $ARGV[1];

### Configuring an Excel Workbook ###
my $workbook  = Spreadsheet::WriteExcel->new("$excel_file.xls");
my $worksheet = $workbook->add_worksheet('CoOccurrance');

# Add a sample format
my $format = $workbook->add_format();
$format->set_size(12);
$format->set_bold();
$format->set_color('blue');
$format->set_underline();

### End Config ###


# Open Drug and Query files
open(DFILE, "< $drug_file") || die "cannot open $drug_file: $!\n";

# Start position of results matrix
my $matrix_row = 2; 

# Start position of Drugs header
my $drugColHeadStart = "A"; 

### Header for column 1
$worksheet->write("A1", "SearchLITE");

# MeSH url shortcut
my $mesh = "http://www.nlm.nih.gov/cgi/mesh/2004/MB_cgi?term=";

# Write our Drug names in the first column of the spreadsheet

# Loops through Drug file
READ_DRUG_LOOP:while (<DFILE>)
{
	chomp; # remove newlines
	
# Assign drug query
	my $drugExp = $_;
	
# If it contains a regular expression - get rid of it
	my ($drugName) = ($drugExp =~ m/^(.+)\[.+$/) ? $1 : $drugExp;
	print $drugName, "\n";


# Write our Drug names in the first column of the spreadsheet
# Start at row #2 as row #1 has query headers
	$worksheet->write("$drugColHeadStart$matrix_row",  "$mesh$drugName",   "$drugName"              );

	
# Add to row co-ordinates to assign next result position		
	$matrix_row++;
	
}# End DRUG_LOOP

# Close the file we've opened
close(DFILE);
