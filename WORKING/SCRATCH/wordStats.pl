#!/usr/bin/perl
use strict;
use warnings;

my $usage = "Usage:wordStats.pl termOntol_byFreq 

\toptional use:
\tfile1:termOntol_byFreq   file2:ctrlOntol_byFreq
\n";

unless ( $ARGV[0] ) { die $usage }

# Take input from the command line

my $termFile = $ARGV[0];
my $ctrlFile = $ARGV[1];

# declare hash for term(freq}
my %wordHash;

open(TFILE, "< $termFile") || die "cannot open $termFile: $!\n";

# declare variables for sum of all hits and word count
my ($totalHits, $howManyWords);

# array to collect word freqs
my @wordCounts;

# count all hits; count how many words
# hash of tems with count as value
while (<TFILE>)
{
  chomp;
  my ($count, $term) = split(/\t/, $_);
  $totalHits += $count;
  $howManyWords++;
  $wordHash{$term} = "$count";
  push (@wordCounts, $count);
}

# Close the file we've opened
close(TFILE);

# define hash for control corpus
my %cWordHash;

# open control corpus term freq file
open(CFILE, "< $ctrlFile") || die "cannot open $ctrlFile: $!\n" if $ctrlFile;

# declare variables for sum of all hits and word count
my ($ctrlHits, $cHowManyWords);
my @cWordCounts;

# if we've supplied two files then we'll apply ctrl corpus
# term weighting to second file
if ($ctrlFile) {

# count all hits; count how many words
# hash of tems with count as value
while (<CFILE>)
{
  chomp;
  my ($cCount, $cTerm) = split(/\t/, $_);
  $ctrlHits += $cCount;
  $cHowManyWords++;
  $cWordHash{$cTerm} = "$cCount";
  push (@cWordCounts, $cCount);
}

# Close the file we've opened
close(CFILE);
} # end if $ctrlFile

my $avg = &average(\@wordCounts);
my $cAvg = &average(\@cWordCounts) if $ctrlFile;

#print $cAvg, "\n" if $ctrlFile;
#my $std = &stdev(\@wordCounts);
#print $ave, "\t", $std, "\n";

foreach my $key (sort { $wordHash {$b} <=> $wordHash {$a}} keys %wordHash) 
{
  my $norm = sprintf("%.2f", $wordHash{$key} / $avg);

  print $norm, "\t", $wordHash{$key}, "\t", $key, "\n" unless $ctrlFile; 
  
  if ($ctrlFile) {
    if ( exists $cWordHash{$key} ) {

      my $weightVal = sprintf("%.2f",  $cWordHash{$key} / $cAvg);        
      print $weightVal, "\t", $wordHash{$key}, "\t", $key, "\n";
      } else {
      print "new term", "\t", $wordHash{$key}, "\t", $key, "\n";
    }
  }
}

### Subroutines ###

sub average{
        my($data) = @_;
        if (not @$data) {
                die("Empty array\n");
        }
        my $total = 0;
        foreach (@$data) {
                $total += $_;
        }
        my $average = $total / @$data;
        return $average;
}

sub stdev{
        my($data) = @_;
        if(@$data == 1){
                return 0;
        }
        my $average = &average($data);
        my $sqtotal = 0;
        foreach(@$data) {
                $sqtotal += ($average-$_) ** 2;
        }
        my $std = ($sqtotal / (@$data)) ** 0.5;
        return $std;
}


