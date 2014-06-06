#!/usr/bin/perl
use strict;
use warnings;
use XML::XPath;
use XML::XPath::XMLParser;

# Take input from the command line

my $inFile = $ARGV[0];

open(IFILE, "< $inFile") || die "cannot open $inFile: $!\n";

$/ = undef;

my @entries;
my @lines;

while (<IFILE>)
{
	@entries = split(/\n\n/, $_);
}

# Close the file we've opened
close(IFILE);

$/ = "\n";

      foreach my $entry (@entries)
      {
	#print "\nNEW ENTRY: \n", $entry, "\nEND ENTRY\n\n";

	@lines = split(/\n/, $entry);
	    
	foreach my $line (@lines)
	{
	  #print "LINE: ", $line, "\n";
	  #chomp;

	if ($line =~ (/ArticleTitle/) ) 
	{
		my $title = $line;
		$title =~ s/^\s+//g;
		$title =~ s/[\<\/\>]//g;		
		$title =~ s/ArticleTitle//g;
#		$words .= $title;
		print "TITLE: ", $title, "\n***\n";
	}
	
	if ($line =~ (/AbstractText/) )
	{
		my $abst = $line;
		$abst =~ s/^\s+//g;
		$abst =~ s/ Label\=.+?\"\>//g;
		$abst =~ s/[\<\/\>]/ /g;		
		$abst =~ s/AbstractText//g;
#		$words .= $abst;
		print "ABSTRACT: ", $abst, "\n***\n\n";
	}

	}
}


