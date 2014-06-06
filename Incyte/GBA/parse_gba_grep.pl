#!/usr/local/bin/perl -w
#
#
#
#

use Getopt::Std;
use POSIX;
use strict;

$| = 1;

my $usage = "Usage:parse_gba_grep.pl [-h] [-g] [-a] [-c <number>]" .
    " pattern_file gb_grep_results_file

\t-h help
\t-c cut off for core members hit 
\t   (default >= 2 core members)

\t-g core members which hit other cores
\t-a alternative output: 
\t   cand_lg_id CG_lg_id GBA_score
";

unless ( $ARGV[1] ) { die $usage }

### command line options ###
my (%opts, $cutoff, $number, $core2core, $candcore);

getopts('hc:ga', \%opts);
defined $opts{"h"} and die $usage;

defined $opts{"g"} and $core2core++;

defined $opts{"a"} and $candcore++;

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
  print STDERR "No cutoff specified. Defaulting to >= 2 core member\n";
  $number = 2;
}

open(CORE2CORE, "> core2core") 
    || die "cannot open core2core: $!" if $core2core;

print STDERR "Core genes which GBA with other core genes" .
    " written to file:core2core\n" if $core2core;

print STDERR "Alternative output selected: " .
    "Candidate Core GBA_score\n" if $candcore;

### Main program ###
my $pattern_file = $ARGV[0];
my $results_file = $ARGV[1];

open(PATTERN_FILE, "< $pattern_file") 
    || die "cannot open $pattern_file: $!";

my @pattern_list = ();

while (<PATTERN_FILE>)
{
  chomp;
#  print "$_\n";
  push(@pattern_list, $_);
}

close(PATTERN_FILE) 
    || die "cannot close $pattern_file: $!";

my ($gene_id1, $gene_id2, $score);
my ($pattern);
my %gba_hits = ();
my %gba_counts = ();

open(RESULTS_FILE, "< $results_file") 
    || die "cannot open $results_file: $!";

READ_LOOP: while (<RESULTS_FILE>)
{
  chomp;
  ($gene_id1, $gene_id2, $score) = split(/\t/, $_);

  if ( (CG_present($gene_id1, @pattern_list)) &&
       (CG_present($gene_id2, @pattern_list)) )
  {
    print CORE2CORE "Two cores: $gene_id1\t" .
	"\t$gene_id2\t$score\n" if $core2core;
    next READ_LOOP;
  }

  foreach $pattern (@pattern_list)
  {
    if ($pattern eq $gene_id1)
    {
      push( @{ $gba_hits{$gene_id2} }, [$score, $gene_id1]);
      $gba_counts{$gene_id2}++;
    }
     elsif ($pattern eq $gene_id2)
    {
      push( @{ $gba_hits{$gene_id1} },  [$score, $gene_id2]);
      $gba_counts{$gene_id1}++;
    }
  }
}

close (RESULTS_FILE) 
    || die "cannot close $results_file: $!";

close (CORE2CORE) 
    || die "cannot close core2core: $!" if $core2core;

my $gba_count;
my $gba_hit;
my $i;

 foreach $gba_count (sort keys %gba_counts)
 {
   if ($gba_counts{$gba_count} >= $number)
   {
     print "$gba_count : Hit $gba_counts{$gba_count} " .
	 "CGC candidates!\n" unless $candcore;
       for $i (0 .. $#{ $gba_hits{$gba_count} })
       {
 	my ($hash_score, $query_id) = @{ $gba_hits{$gba_count}->[$i] };
 	print "$query_id\t$hash_score\n" unless $candcore;
	print "$gba_count\t$query_id\t$hash_score\n" if $candcore;
       }
     print "=\n" unless $candcore;
   }
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

# checks whether the lg id #
# is in the pattern file.  #
# returns true if present. #
sub CG_present
{

  my $pattern;

  my $lg = shift;
  my @CG_file = @_;

  foreach $pattern (@CG_file)
  {
    if ($pattern eq $lg)
    {
      return 1;
    }
  }

}
