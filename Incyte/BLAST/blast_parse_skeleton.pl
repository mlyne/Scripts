#!/usr/local/bin/perl -w

# supply path for additional perl modules
BEGIN{ push(@INC, "/home/mlyne/SCRIPTS/AnT/Bio-PSU-0.05") }

use strict;
use Bio::PSU::SearchFactory;

my $file = shift;

my $blast = Bio::PSU::SearchFactory->make(-file      => "$file",
					  -program   => 'blast');
  
while (my $result = $blast->next_result)
{
  printf("type %s, query %s, db %s\n",
	 $result->type,
	 $result->q_id,
	 $result->database);
      
  while (my $hit = $result->next_hit)
  {
    printf("\tsubject: id %s,  desc %s, len %s\n",
	   $hit->s_id,
	   $hit->s_desc,
	   $hit->s_len);
	
    while (my $hsp = $hit->next_hsp)
    {
      printf("\t\tscore %s, expect %s, percent %s\n",
	     $hsp->score,
	     $hsp->expect,
	     $hsp->percent);
      
      printf("\t\tquery start %d, q end %s\n",
	     $hsp->q_begin,
	     $hsp->q_end);
	  
      printf("\t\tsubject start %d, s end %s\n",
	     $hsp->s_begin,
	     $hsp->s_end);
    }
  }
}

