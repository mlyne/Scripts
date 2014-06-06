#!/usr/bin/perl
use strict;
use warnings;

#my $usage = "Usage:terms2mesh.pl pubmed_xml search_term_file\n";
#unless ( $ARGV[1] ) { die $usage }

# Take input from the command line

my $ctrlFile = $ARGV[0];
my $testFile = $ARGV[1];

my %wordHash;

open(IFILE, "< $ctrlFile") || die "cannot open $ctrlFile: $!\n";

my $totalHits;
my $howManyWords;

while (<IFILE>)
{
  chomp;
  my ($count, $term) = split(/\t/, $_);
  $totalHits += $count;
  $howManyWords++;
  $wordHash{$term} = "$count";
}

# Close the file we've opened
close(IFILE);

my %tWordHash;

open(TFILE, "< $testFile") || die "cannot open $testFile: $!\n";

my $testHits;
my $tHowManyWords;

while (<TFILE>)
{
  chomp;
  my ($tcount, $tterm) = split(/\t/, $_);
  $testHits += $tcount;
  $tHowManyWords++;
  $tWordHash{$tterm} = "$tcount";
}

# Close the file we've opened
close(TFILE);


my $avg = $totalHits / $howManyWords;
my $tAvg = $testHits / $tHowManyWords;

#print map { "$_ => $wordHash{$_}\n" } keys %wordHash;

my %corpusNorm;

foreach my $key (sort { $wordHash {$b} <=> $wordHash {$a}} keys %wordHash) 
{
  my $norm = sprintf("%.2f", $wordHash{$key} / $avg);
  $corpusNorm{$key} = $norm;
#  print $key, "\t", $wordHash{$key}, "\t", $norm, "\n"; 
}

foreach my $key (sort { $tWordHash {$b} <=> $tWordHash {$a}} keys %tWordHash) 
{
  my $norm = sprintf("%.2f", $tWordHash{$key} / $tAvg);
  if ( exists  $corpusNorm{$key} )
    {
    my $normVal = sprintf("%.2f", $tWordHash{$key} / $corpusNorm{$key});
    print $normVal, "\t", $tWordHash{$key}, "\t", $key,, "\n"; 
  }
}
#print "Total: ", $totalHits, " Words: ", $howManyWords, " Avg: ", $avg, "\n";


