#!/usr/bin/perl -w

# pragmas
use strict;

# used in conjunction with SCRIPTS/HANDY/meshDef.pl
# extracts search term and mesh definition

while (<>) 
    {    
    chomp;
    
	my @lines = split(/\n/, $_);
	foreach my $line (@lines)
	{
		chomp;
	  	
	  	if ($line =~ /TEXT\" value=\"(.+?)\"/)
		{
	  		my $term = $1;
	  		print "$term\n";
	  	}
	  	
	  	if ($line =~ /<dd>(.+?)<br>/)
		{
	  		my $def = $1;
	  		print "$def\n\n";
	  	}
  	}
}