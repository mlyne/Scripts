#!/usr/bin/perl
use strict;
use warnings;

my $usage = "Usage:wordStats_2.pl cntrlSampleOntol_byFreq \[optional F2 testOntolFile_byFreq\]\n";
unless ( $ARGV[0] ) { die $usage }

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

open(TFILE, "< $testFile") || die "cannot open $testFile: $!\n" if $testFile;

my $testHits;
my $tHowManyWords;

if ($testFile) {

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
} # end if $testFile

my $avg = $totalHits / $howManyWords;
my $tAvg = $testHits / $tHowManyWords if $testFile;

#print map { "$_ => $wordHash{$_}\n" } keys %wordHash;

my %corpusNorm;

foreach my $key (sort { $wordHash {$b} <=> $wordHash {$a}} keys %wordHash) 
{
  my $norm = sprintf("%.2f", $wordHash{$key} / $avg);
  $corpusNorm{$key} = $norm;
  print $norm, "\t", $wordHash{$key}, "\t", $key, "\n" unless $testFile; 
}

if ($testFile) {
foreach my $key (sort { $tWordHash {$b} <=> $tWordHash {$a}} keys %tWordHash) 
{
  my $norm = sprintf("%.2f", $tWordHash{$key} / $tAvg);
  if ( exists  $corpusNorm{$key} )
    {
    my $normVal = sprintf("%.2f", $tWordHash{$key} / $corpusNorm{$key});
    print $normVal, "\t", $tWordHash{$key}, "\t", $key,, "\n"; 
  }
}
} # end if $testFile
#print "Total: ", $totalHits, " Words: ", $howManyWords, " Avg: ", $avg, "\n";


