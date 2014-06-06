#!/usr/local/bin/perl -w
#
# Takes sorted MSPcrunch output
# and makes a hash of the Query
# sequence giving hits and Gold id

use strict;

my $usage = "Usage:msp_out_parse.pl num_sorted_MSPcrunch_file\n";

unless ( $ARGV[0] ) { die $usage }

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
  $lg_id = $msp_line[-1];

  push( @{ $core_hash{$locus} }, [$score, $lg_id]);

}
  
my $i;
my $core_hit;

foreach $core_hit (sort keys %core_hash)
{
  print "LOCUS:\t$core_hit\n";
  print "Score\tLG id\n";
  for $i (0 .. $#{ $core_hash{$core_hit} })
  {
    my ($hit_score, $hit_lg_id) = @{ $core_hash{$core_hit}->[$i] };
    print "$hit_score\t$hit_lg_id\n";
  }
}
