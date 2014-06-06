#!/usr/bin/perl -w

use strict;

my $in_file = $ARGV[0];
open(IFILE, "< $in_file") || die "cannot open $in_file: $!\n";
#local $/;

my $words;

while (<IFILE>) {
	chomp;
	my $line = $_;
	if ($line =~ (/ArticleTitle/) ) {
		my $title = $line;
		$title =~ s/^\s+//g;
		$title =~ s/[\<\/\>]//g;		
		$title =~ s/ArticleTitle//g;
		$words .= $title;
#		push(@words, $title);
#		print $title, "\n***\n\n";
	}
	
		if ($line =~ (/AbstractText/) ) {
		my $abst = $line;
		$abst =~ s/^\s+//g;
		$abst =~ s/[\<\/\>]//g;		
		$abst =~ s/AbstractText//g;
		$words .= $abst;
#		push(@words, $abst);
#		print $abst, "\n***\n\n";
	}
	
	

}
close (IFILE);

print $words;

