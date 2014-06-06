#!/usr/local/bin/perl -w
#
#
#
#

use Getopt::Std;
use POSIX;
use strict;

my $usage = "Usage:parse_gba_grep.pl [-c <number>] poss_xref_cands_file

\t-h help
\t-c number of candidates which hit a core genes (default <= 20)
\n";

unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts, $cutoff, $number, $output);

getopts('hc:', \%opts);
defined $opts{"h"} and die $usage;

defined $opts{"c"} and $cutoff = $opts{"c"};
if (defined $cutoff)
{
  $number = getnum($cutoff);
  unless ($number)
  {
    die "Invalid cutoff value: $cutoff\n";
  }
}
else
{
  print STDERR "No cutoff specified. Defaulting to <= 20\n";
  $number = 20;
}

my $cand_file = $ARGV[0];

my ($gene_id1, $gene_id2, $score);
my %gba_hits = ();
my %gba_counts = ();

open(CAND_FILE, "< $cand_file") || die "cannot open $cand_file: $!\n";

while (<CAND_FILE>)
{
  chomp;
  ($gene_id1, $gene_id2, $score) = split(/\s+/, $_);

  push( @{ $gba_hits{$gene_id1} },  [$score, $gene_id2]);
  $gba_counts{$gene_id1}++;
}

my $gba_count;
my $gba_hit;
my $i;

open(CANDIDATES, "> putative_candidates_from_gba") 
      || die "cannot open putative_candidates_from_gba: $!";

foreach $gba_count (sort keys %gba_counts)
{
  if (($gba_counts{$gba_count} >1)
      && ($gba_counts{$gba_count} <= $number))
  {
    print "$gba_count\n";
    for $i (0 .. $#{ $gba_hits{$gba_count} })
    {
      my ($hash_score, $query_id) = @{ $gba_hits{$gba_count}->[$i] };
#      print "$query_id\t$hash_score\n";
      print CANDIDATES "$query_id\n";
      print "$query_id\n";
    }
  }
}

close(CANDIDATES) || die "cannot close putative_candidates_from_gba: $!";


###             ###
### subroutines ###
###             ###

# checks to see whether the value #
# returned is a number - returns  #
# the number if true, or undef if #
# false                           #
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

