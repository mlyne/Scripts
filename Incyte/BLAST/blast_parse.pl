#!/usr/local/bin/perl -w

# supply path for additional perl modules
BEGIN{ push(@INC, "/home/mlyne/SCRIPTS/AnT/Bio-PSU-0.05") }

use strict;
use Bio::PSU::SearchFactory;

STDOUT->autoflush (1);
STDERR->autoflush (1);

my $file = shift;
my $blast = Bio::PSU::SearchFactory->make(-file      => "$file",
					  -program   => 'blast');

my ($query_id, $query_len);
my ($subj_id, $subj_len);
my ($percent, $query_beg, $query_end, $subj_beg, $subj_end);
 
while (my $result = $blast->next_result)
{
  $query_id = $result->q_id;
  $query_len = $result->q_len;

#  print "Query ID:$query_id\n";

      
  while (my $hit = $result->next_hit)
  {
    $subj_id = $hit->s_id;
    $subj_len = $hit->s_len;

#    print "Subj ID:$subj_id\n";

    next if ($subj_id eq $query_id);

    my @q_coverage = ();
    my @s_coverage = ();
    my @percentage = ();
	
    while (my $hsp = $hit->next_hsp)
    {
      $percent = $hsp->percent;
      push(@percentage, $percent);

      $query_beg = $hsp->q_begin;
      $query_end = $hsp->q_end;
      my $q_coverage = $query_end-$query_beg;
      push(@q_coverage, $q_coverage);
	
      $subj_beg = $hsp->s_begin,
      $subj_end = $hsp->s_end;

      if ($subj_end > $subj_beg)
      {
	my $s_coverage = $subj_end-$subj_beg;
	push(@s_coverage, $s_coverage);
      }
      elsif ($subj_beg > $subj_end)
      {
	my $s_coverage = $subj_beg-$subj_end;
	push(@s_coverage, $s_coverage);
      }
    }

#    print "\@Perc:", scalar(@percentage), "\n";
#    print "\@q_coverage:", scalar(@q_coverage), "\n";
#    print "\@s_coverage:", scalar(@s_coverage), "\n";

    my ($p, $total_perc);
    foreach $p(@percentage)
    {
      $total_perc += $p;
    }
    
    my $final_perc = $total_perc / scalar(@percentage) if (@percentage);
    
    my ($q_cov, $total_qcov);
    foreach $q_cov(@q_coverage)
    {
      $total_qcov += $q_cov;
    }

    if ($total_qcov > $query_len)
    {
      $total_qcov = $q_coverage[0];
    }
    
    my ($s_cov, $total_scov);
    foreach $s_cov(@s_coverage)
    {
      $total_scov += $s_cov;
    }

    if ($total_scov > $subj_len)
    {
      $total_scov = $s_coverage[0];
    }

    @q_coverage = ();
    @s_coverage = ();
    @percentage = ();

#-----------------------------------------------------------------------------------
    if ($query_len <= $subj_len)
    {
      if (($total_qcov / $query_len> 0.9)
	  && ($final_perc > 90))
      {
	print "$query_id\t$query_len\t$subj_id\t$subj_len\t$total_qcov\t$final_perc\n";
#	print "Very Close hit!\n";
#	print "Query: $query_id, Length: $query_len\n";
#	print "Subject: $subj_id, Length: $subj_len\n";
#	print "Query coverage: $total_qcov bp over $query_len bases\n";
#	print "Percentage Identity: $final_perc\n\n";
      }
    } 

    if ($query_len > $subj_len)
    {
      if (($total_scov / $subj_len> 0.9)
	  && ($final_perc > 90))
      {
	print "$query_id\t$query_len\t$subj_id\t$subj_len\t$total_scov\t$final_perc\n";
#	print "Very Close hit!\n";
#	print "Query: $query_id, Length: $query_len\n";
#	print "Subject: $subj_id, Length: $subj_len\n";
#	print "Query coverage: $total_scov bp over $subj_len bases\n";
#	print "Percentage Identity: $final_perc\n\n";
      }
    } 

  }
}

