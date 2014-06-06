#!/usr/local/bin/perl -w
#
#
#

use Getopt::Std;
use POSIX;
use strict;

my $usage = "Usage:gba_xref_parse.pl [-h] [-c <number>] [-o] gba_xref_file

\t-h help
\t-o output a list of 'candidates_from_gba'
\t-c cutoff value e.g. 0.0001 or 1.0e-05, (default 0.001)
\n";

unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts, $cutoff, $number, $output);

getopts('hc:o', \%opts);
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
  print STDERR "No cutoff specified. Defaulting to 0.001\n";
  $number = 0.001;
}

defined $opts{"o"} and $output++;


### script body ###

my $gba_xref = $ARGV[0];

open(XREF_FILE, "< $gba_xref") || die "cannot open $gba_xref: $!";

my @gba_records = ();

$/ = undef;

while (<XREF_FILE>)
{
  chomp;
  @gba_records = split(/=/, $_);
}

close(XREF_FILE) || die "cannot close $gba_xref: $!";

$/ = "\n";

my ($gba_record);
my @gba_lines = ();
my ($gba_line);
my ($gba_hit, $core, $gba_score);
my %candidates = ();
my ($candidate);

foreach $gba_record (@gba_records)
{
  @gba_lines = split(/\n/, $gba_record);

  foreach $gba_line (@gba_lines)
  {
    if ($gba_line =~ /(\d+)\s:\s/)
    {
      $gba_hit = $1;
    }

    if ($gba_line =~ /(\d+)\t(\d+.*)$/)
    {
      ($core, $gba_score) = ($1, $2);
#      print "$core, $gba_score\n";

      if (($gba_score < $number) 
	  && ($gba_score != 0))
      {
	$candidates{$gba_hit}++;
	print "$gba_hit\t$gba_score\t$core\n";
      }

    }    
  }
}

candidate_list() if $output;

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


sub candidate_list
{

  open(CANDIDATES, "> candidates_from_gba") 
      || die "cannot open candidates_from_gba: $!";

  foreach $candidate (sort keys %candidates)
  {
    if ($candidates{$candidate} > 3)
    {
      print CANDIDATES "$candidate\n";
    }
  }

  close(CANDIDATES) || die "cannot close candidates_from_gba: $!";
}
