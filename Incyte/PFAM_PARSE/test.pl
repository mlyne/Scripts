#!/usr/local/bin/perl -w
#
# works with hmmpfam results
# e.g. cat *.hmmpfam | hmmpfam_parse.pl

use strict;

#my $usage = "Usage: hmmpfam_parse.pl hmmpfam_out_file\n";

#unless ( $ARGV[0] ) { die $usage }

#$/ = "//";
$| = 1;
 
READ_LOOP: while (<>)
{

  my $line;
  my @results = ();
  while (<>) 
  {
    chomp;
    $line = $_;
    if (/Parsed for domains:/ ... /Alignments of top-scoring domains:/) 
    {
      unless ($line =~ /^Parsed/ || /^Model/ || /^--------/ 
	      || /no hits above thresholds/ || /^$/ || /^Alignments/)
      {
	print "$line\n";
      }
    }
  }

  next READ_LOOP;
}


