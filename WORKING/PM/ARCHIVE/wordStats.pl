#!/usr/bin/perl
use strict;
use warnings;

my $usage = "Usage:wordStats_3.pl testOntol_byFreq 

\toptional use:
\tfile1:testOntol_byFreq   file 2:ctrlOntol_byFreq
\n";

unless ( $ARGV[0] ) { die $usage }

# Take input from the command line

my $testFile = $ARGV[0]; # this was file 2 [1]
my $ctrlFile = $ARGV[1]; # this was file 1 [0]

# declare hash for term(freq}
my %wordHash;

open(CFILE, "< $ctrlFile") || die "cannot open $ctrlFile: $!\n";

# declare variables for sum of all hits and word count
my ($totalHits, $howManyWords);

# array to collect word freqs
my @wordCounts;

# count all hits; count how many words
# hash of tems with count as value
while (<CFILE>)
{
  chomp;
  my ($count, $term) = split(/\t/, $_);
  $totalHits += $count;
  $howManyWords++;
  $wordHash{$term} = "$count";
  push (@wordCounts, $count);
}

# Close the file we've opened
close(CFILE);

my %tWordHash;

open(TFILE, "< $testFile") || die "cannot open $testFile: $!\n" if $testFile;

# declare variables for sum of all hits and word count
my ($testHits, $tHowManyWords);
my @twordCounts;

# if we've supplied two files then apply ctrl corpus
# term weighting to second file
if ($testFile) {

# count all hits; count how many words
# hash of tems with count as value
while (<TFILE>)
{
  chomp;
  my ($tcount, $tterm) = split(/\t/, $_);
  $testHits += $tcount;
  $tHowManyWords++;
  $tWordHash{$tterm} = "$tcount";
  push (@twordCounts, $tcount);
}

# Close the file we've opened
close(TFILE);
} # end if $testFile

my $avg = &average(\@wordCounts);
my $tAvg = &average(\@twordCounts) if $testFile;
#my $std = &stdev(\@wordCounts);

#print $ave, "\t", $std, "\n";

my %corpusNorm;

foreach my $key (sort { $wordHash {$b} <=> $wordHash {$a}} keys %wordHash) 
{
  my $norm = sprintf("%.2f", $wordHash{$key} / $avg);
  $corpusNorm{$key} = $norm;
  print $norm, "\t", $wordHash{$key}, "\t", $key, "\n" unless $testFile; 
}

# if ($testFile) {
# foreach my $key (sort { $wordHash {$b} <=> $wordHash {$a}} keys %wordHash) 
# {
#   my $norm = sprintf("%.2f", $tWordHash{$key} / $tAvg);
#   if ( exists  $tWordHash{$key})
#     {
#     my $normVal = sprintf("%.2f", $tWordHash{$key} / $corpusNorm{$key});
#     print $normVal, "\t", $tWordHash{$key}, "\t", $key, "\n"; 
#     }
# #   } else {
# #     print $norm, "\t", $wordHash{$key}, "\t", $key, "\n"; ## provis solution
# #   }
# }
# } # end if $testFile

if ($testFile) {
foreach my $key (sort { $tWordHash {$b} <=> $tWordHash {$a}} keys %tWordHash) 
{
  my $norm = sprintf("%.2f", $tWordHash{$key} / $tAvg);
  if ( exists  $corpusNorm{$key} )
    {
    my $normVal = sprintf("%.2f", $tWordHash{$key} / $corpusNorm{$key});
    print $normVal, "\t", $tWordHash{$key}, "\t", $key, "\n"; 
    }
#   } else {
#     print $norm, "\t", $wordHash{$key}, "\t", $key, "\n"; ## provis solution
#   }
}
} # end if $testFile
#print "Total: ", $totalHits, " Words: ", $howManyWords, " Avg: ", $avg, "\n";

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


