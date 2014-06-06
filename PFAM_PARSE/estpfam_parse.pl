#!/usr/local/bin/perl -w
#
# Takes (est)hmmpfam results e.g.
# and gives a list of templates
# and domains/scores > 0
# e.g. cat *.esthmmpfam | estpfam_parse.pl
#
# Template       Domain  bit E-val
# LG:1000914.1   pkinase 4.7 3.3

use strict;

$/ = "//";
$| = 1;
 


READ_LOOP: while (<>)
{
  my ($query, $score, $result, $result_array);
  my @result_array = ();

  unless ($_ =~ /threshold/)
  {
    if (/score\s+\d/)
    {
      my @split_result = split( m(\n), $_ );

      RESULTS_LOOP: foreach my $line ( @split_result )
      {
	
	if ($line =~ /Query:\s+(.*)/)
	{
	  $query = $1;
	}
      
	if (($line =~ /\d\s\.\.\s/) 
#	    && ($line !~ /(?:\[|\]|\.\.)/)
	    && ($line !~ /\s-\d/))
	{
#	  $line =~ s/(.*\s+\d+)\s+(?:<-|->)/$1/;
#	  ($score) = $line =~ /(\d+\.\d)\s+\d/;
	  @result_array = split(/\s+/, $line);

	  if ($result_array[-3] > 1) #ie. Score
	  {
	    print "$query ", $result_array[0], " ", 
	    $result_array[-3], " ", $result_array[-2], "\n";
	  }

	}

	next RESULTS_LOOP;

      }


    }
  }
  next READ_LOOP;
}


