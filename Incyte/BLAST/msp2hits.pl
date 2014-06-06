#!/usr/local/bin/perl -w
#
# Takes sorted MSPcrunch output
# and makes a hash of the Query
# sequence giving score, Query seq,
# hit. May need to sort -u output

use Getopt::Std;
use strict;

my $usage = "Usage:msp2rows_hits.pl [-h] [-t] num_sorted_MSPcrunch_file

\t-h help
\t-t top hit only

Takes sorted MSPcrunch file as input
and ouputs MSP score, Query
and hit. Minus t option just
gives the top-hit for each Query.
May need to sort -u output?
\n";

### command line options ###
my (%opts, $top_hit);

getopts('ht', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"t"} and $top_hit++;

unless ( $ARGV[0] ) { warn $usage }

my @msp_line;
my $line;
my ($score, $locus, $lg_id);
my %core_hash;

while (<>)
{
  @msp_line = ();
  chomp;
  s/^\s+//g;
  $line = $_;
  @msp_line = split(/\s+/, $line);
  $score = $msp_line[0];
  $locus = $msp_line[4];
  $lg_id = $msp_line[7];

  push( @{ $core_hash{$locus} }, [$score, $lg_id]);

}
  
my $i;
my $core_hit;

foreach $core_hit (sort keys %core_hash)
{
  my ($hit_score, $hit_lg_id);
#  print "$core_hit\t";
  for $i (0 .. $#{ $core_hash{$core_hit} })
  {
    ($hit_score, $hit_lg_id) = @{ $core_hash{$core_hit}->[$i] } unless $top_hit;
    ($hit_score, $hit_lg_id) = @{ $core_hash{$core_hit}->[0] } if $top_hit;
    print "$hit_score\t$core_hit\t$hit_lg_id\n" unless $top_hit;
  }
print "$hit_score\t$core_hit\t$hit_lg_id\n" if $top_hit;
}
