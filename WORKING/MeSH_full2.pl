#!/usr/bin/perl -w

use strict;
 
my $file = $ARGV[0];

open(FILEO, "< $file") || die "cannot open $file: $!\n";

my @array;
{
 local $/ = '</html>';
 @array = <FILEO>;
}

foreach my $entry (@array)
{
	
	if ( $entry =~ /term\".+?value=\"(.+?).>/smi ) {
		my $term = $1;
		print "Term: ", $term, "\n";
	}
	
	if ( $entry =~ /All MeSH Categories(.+)<\/ul>/smi ) {
		my $val = $1;
		$val =~ s/<dt><a href.+//gm;
		$val =~ s/All MeSH Categories\n//gm;
		$val =~ s/^.+?=Full.>//gm;
		$val =~ s/.+?>//gm;
		$val =~ s/^\n//gm;
		$val =~ s/\+\n//gm;
		$val =~ s/.+?Category\n/\n/gm;
		print $val, "\n";
	}
	
	print "***********\n";

#	print "***\nStart\n", $entry, "\nEnd\n***\n";
	
}