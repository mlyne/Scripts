#!/usr/local/bin/perl -w
#
# Takes sorted MSPcrunch output
# and makes a hash of the Query
# sequence giving score, Query seq,
# hit. 

use Getopt::Std;
use POSIX;
use strict;

my $usage = "Usage:msp2rows_hits.pl [-h] [-t] [-r] <int> num_sorted_MSPcrunch_file

\t-h     help
\t-t     top hit only
\t-r     number of results to report

Takes sorted MSPcrunch file as input
and ouputs MSP score, Query
and hit. Minus t [-t] option just
gives the top-hit for each Query.
Minus r option [-r] followed by an
integer will report that number of
hits (or all hits if int > hit total)
\n";

### command line options ###
my (%opts, $top_hit, $res2report, $res_count);

getopts('htr:', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"t"} and $top_hit++;
defined $opts{"r"} and $res2report = $opts{"r"};
if ($res2report)
{
  $res_count = getnum($res2report);
}

unless ( $ARGV[0] ) { warn $usage }

my @msp_line;
my $line;
my ($score, $percId, $q_start, $q_end, $queryId, $s_start, $s_end, $subjId, $desc);
my ($quer_len, $subj_len);
my %core_hash;

while (<>)
{
  @msp_line = ();
  chomp;
  s/^\s+//;
  $line = $_;
  @msp_line = split(/\s+/, $line, 9);
  $score = $msp_line[0];
  $percId = $msp_line[1];
  $q_start = $msp_line[2];
  $q_end = $msp_line[3];
  $queryId = $msp_line[4];
  $s_start = $msp_line[5];
  $s_end = $msp_line[6];
  $subjId = $msp_line[7];
  $desc = defined($msp_line[8]) ? ($msp_line[8]) : "no description";

#  print "big $desc pants\n";

  $quer_len = ($q_start > $q_end) ? ($q_start - $q_end) : ($q_end - $q_start);
  $subj_len = ($s_end - $s_start);

  push( @{ $core_hash{$queryId} }, [$score, $percId, $quer_len, $queryId, $subj_len, $subjId, $desc]);

}
  
my ($value, $i);
my $core_hit;

foreach $core_hit (sort keys %core_hash)
{

#  print "Array_count = ", $#{ $core_hash{$core_hit} }, "\n";

  $value = ($res_count - 1) if (defined($res_count));
  $value = ($res_count <= $#{ $core_hash{$core_hit} }) ? ($res_count - 1) : $#{ $core_hash{$core_hit} }
  if (defined($res_count));
  $value ||= $#{ $core_hash{$core_hit} };

#  print "value = $value\n";

  my ($hit_score, $hit_percId, $hit_qlen, $hit_queryId, $hit_slen, $hit_subjId, $hit_desc);

  for $i (0 .. $value)
  {
    ($hit_score, $hit_percId, $hit_qlen, $hit_queryId, $hit_slen, $hit_subjId, $hit_desc) = @{ $core_hash{$core_hit}->[$i] } unless $top_hit;
    ($hit_score, $hit_percId, $hit_qlen, $hit_queryId, $hit_slen, $hit_subjId, $hit_desc) = @{ $core_hash{$core_hit}->[0] } if $top_hit;
    print "$hit_score\t$hit_percId\t$hit_qlen\t$hit_queryId\t$hit_slen\t$hit_subjId\t$hit_desc\n" unless $top_hit;
  }
print "$hit_score\t$hit_percId\t$hit_qlen\t$hit_queryId\t$hit_slen\t$hit_subjId\t$hit_desc\n" if $top_hit;
}


###             ###
### subroutines ###
###             ###

# checks to see whether the value #
# returned is a number - returns  #
# the number if true              #
sub getnum
{
  use POSIX qw(strtod);
  my $str = shift;
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  $! = 0;
  my($num, $unparsed) = strtod($str);
  if (($str eq '') || ($unparsed != 0) || $!)
  {
    return;
  }
  else
  {
    return $num;
  }

}
