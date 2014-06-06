#!/usr/bin/perl -w

use strict;

# Take input from the command line
my $file1 = $ARGV[0];
my $file2 = $ARGV[1];

# Open Drug and Query files
open(FILE1, "< $file1") || die "cannot open $file1: $!\n";
open(FILE2, "< $file2") || die "cannot open $file2: $!\n";


my %hash = ();

# Loops through  file1
READ_FILE1_LOOP:while (<FILE1>)
{
	chomp; # remove newlines
	my ($f1_field, $f1_val) = split("\t", $_);
	#print "$f1_field $f1_val\n";
	$hash{$f1_field} = $f1_val;
}# End FILE1_LOOP
close(FILE1);

print "Indication\t2005\t2004\tGrowth(%)\n";

# Loops over array of Queries
READ_FILE2_LOOP: while (<FILE2>)
{
	chomp; # remove newlines
	my ($f2_field, $f2_val) = split("\t", $_);
	#print "$f2_field $f2_val\n";
	if (exists $hash{$f2_field}) {
		my $growth = sprintf("%.1f", (($f2_val / $hash{$f2_field}) * 100) - 100);
		print $f2_field, "\t", $f2_val, "\t", $hash{$f2_field}, "\t", $growth, "\n";
	}
	else { print $f2_field, "\t", $f2_val, "\tNONE\tNew Indication\n";} 
}# End FILE2_LOOP

# Close the file we've opened

close(FILE2);
