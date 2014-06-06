#!/usr/bin/perl -w

# chemSDparse.pl

# pragmas
use strict;

# modules
use FileHandle;

# Usage
my $usage = "Usage: chemSDparse.pl [--help]

chemSDparse.pl <options> database(s)

\t--help   This list

Used for parsing entries from a PubChem substances SD database(s)
Searches performed with inn[synonym] - display PubChem Download

\n";

unless ( $ARGV[0] ) { die $usage }

# mainline
STDOUT->autoflush (1);
STDERR->autoflush (1);
$/ = undef;

my $ifile;

foreach $ifile (@ARGV) 
{
  my $fh = new FileHandle $ifile, "r";
  if (defined $fh) 
  {
#    print "***reading $ifile***\n";
    while (<$fh>) 
    {
      my @entries = split(/\$\$\$\$\n/, $_);
      
      foreach my $entry (@entries)
      {
	      
		my @fields = split(/\>  /, $entry);
	#	print join("***\n",@fields),"\n";
	    
		foreach my $field (@fields)
		{
			if ($field =~ /^\<ID\>/mg)
			{
			my @array = split('\n', $field);
			print $array[1], "\n";
		}
		}
	}
	}
}
}

   


