#!/usr/local/bin/perl -w
#
#
#
#

use strict;

my $usage = "Usage:gba_grep.pl pattern_file " .
    "Full_path/File_to_search\n";

unless ( $ARGV[1] ) { die $usage }

$| = 1;

my $pattern_list = $ARGV[0];
my $search_file = $ARGV[1];

open(PATTERN_FILE, "< $pattern_list") || die "cannot open $pattern_list: $!";

my $gene_id;
my @grep_results;
my $grep_result;
my ($gba_query, $gba_subject, $gba_score);

while (<PATTERN_FILE>)
{
  chomp;
#  $gene_id = "^${_}[^0-9]";
#  print "$gene_id\n";
  $gene_id = $_;
  @grep_results = ();
#  @grep_results = `grep "$gene_id" $search_file`;
  @grep_results = `grep -w $gene_id $search_file`;

  foreach $grep_result (@grep_results)
  {
    ($gba_query, $gba_subject, $gba_score) = split(/\t/, $grep_result);
    chomp $gba_score;
#    print "$gene_id $gba_query\n";
    if ($gba_score <= 0.001)
    {
      print "$gba_query\t$gba_subject\t$gba_score\n";
    }

  }
}

close(PATTERN_FILE) || die "cannot close $pattern_list: $!";
