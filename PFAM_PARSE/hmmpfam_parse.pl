#!/usr/local/bin/perl -w
#
# works with hmmpfam results
# e.g. cat *.hmmpfam | hmmpfam_parse.pl

use strict;

#my $usage = "Usage: hmmpfam_parse.pl hmmpfam_out_file\n";

#unless ( $ARGV[0] ) { die $usage }

$/ = "//";
$| = 1;
 
READ_LOOP: while (<>)
{
  my ($query, $pfam_id, $score, $evalu);

  unless ($_ =~ /threshold/)
  {
    if (/score\s+\d/)
    {
      my @split_result = split( m(\n), $_ );

      RESULTS_LOOP: foreach my $line ( @split_result )
      {
	
	if ($line =~ /Query:\s+([a-zA-Z0-9_:\.\-]+)/)
	{
	  $query = $1;
	}
      
	if (($line =~ /:\s+domain\s/)
	    && ($line =~ /score\s+\d+\.\d+/))
	{
#	  print "$line\n";
	  ($pfam_id) = $line =~ /^([a-zA-Z0-9_-]+):/;
  	  ($score) = $line =~ /score\s+(\d+\.\d+)/;
	  ($evalu) = $line =~ /\sE\s=\s(.*)$/; 


  	  if ($score > 1)
  	  {
  	    print "$query $pfam_id $score $evalu\n";
  	  }

	}

	next RESULTS_LOOP;

      }


    }
  }
  next READ_LOOP;
}


