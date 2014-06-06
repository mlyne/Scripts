#!/usr/bin/perl
use strict;
use warnings;
use XML::XPath;
use XML::XPath::XMLParser;

# Take input from the command line

my $inFile = $ARGV[0];

my $pubXP = XML::XPath->new(filename=>$inFile);

foreach my $tiNode ($pubXP->find('//DescriptorName')->get_nodelist) {
#	print $tiNode;
	my $title = $tiNode->string_value;
	print $title, "\n";
}
