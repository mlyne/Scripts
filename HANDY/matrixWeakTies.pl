#!/usr/bin/perl
use strict;
use warnings;

my $usage = "Usage:matrixWeakTies.pl 2modeFreq_file 
\n";

unless ( $ARGV[0] ) { die $usage }

# Take input from the command line

my $inFile = $ARGV[0];

# declare hash for term(freq}
my %wordHash;

open(IFILE, "< $inFile") || die "cannot open $inFile: $!\n";

# declare hash of hashes
my (%matrixHoH);

while (<IFILE>)
{
  chomp;
  my ($term1, $term2, $count) = split(/\t/, $_); # split file on TABs
  
# make a Hash of Hashes. Each term1 has a collection of term2s
# Term2 has a value of Freq
# term1->term2 = value  
  $matrixHoH{$term1}{$term2} = $count;
  
}

# Close the file we've opened
close(IFILE);

my (%t1Stats);

foreach my $t1 (keys %matrixHoH) {
  my ($sum, $adjSum, $items, @freqs);
#  print $t1, "\t";
  foreach my $t2 (keys %{ $matrixHoH{$t1} }) {
#    print $t2, "\t", $matrixHoH{$t1}{$t2},
    $items++;
    my $hitCount = $matrixHoH{$t1}{$t2};
    $sum += $hitCount;
    
    if ($hitCount > 100) {
      $adjSum += 100;
    } else {
      $adjSum += $hitCount;
    }
#    $sum += $matrixHoH{$t1}{$t2};
    push (@freqs, $hitCount);
  }

  my @sortFreqs = sort {$b <=> $a} @freqs;
#  print join("\t", @sortFreqs), "\n";
  
  my $highest = $sortFreqs[0];
#  print "\t", $highest, "\n\n";
  $t1Stats{$t1} = [$sum, $adjSum, $items, $highest, \@sortFreqs];
  
#  print "$count\n";
}

print "rank\tfreq\thighest\tterm1\tterm2\tnorMean\tmean\tsum\titems\n";

foreach my $t1 (keys %matrixHoH) {
  my $sum = $t1Stats{$t1}[0];
  my $adjSum = $t1Stats{$t1}[1];
  my $items = $t1Stats{$t1}[2];
  my $highest = $t1Stats{$t1}[3];
#  my @sortFreqs = @{ $t1Stats{$t1}[4] };
  
  my $avg = $sum/$items;
  my $avg2dec = sprintf("%.2f", $avg);
  
  my $normAvg = $adjSum/$items;
  my $normAvg2dec = sprintf("%.2f", $normAvg);
#  my $avg = $t1Stats{$t1}[0] / $t1Stats{$t1}[1];
  
  foreach my $t2 (keys %{ $matrixHoH{$t1} }) {
    my $freq = $matrixHoH{$t1}{$t2};
    
    my $rank = $freq / $normAvg;
    my $rank2dec = sprintf("%.2f", $rank);
    
#    my $adjRank = $rank / $highest;
#    my $adjRank2ec = sprintf("%.2f", $adjRank);
    
    print $rank2dec, "\t", $freq, "\t", $highest, "\t", $t1, "\t", $t2, "\t", $normAvg2dec, "\t", $avg2dec, "\t", $sum, "\t", $items, "\n";
  }
}

# foreach $item (keys %hash){
#   print "$item: ";
#   foreach $iteminitem (keys %{$hash{$item}}){
#     print "$iteminitem = $hash{$item}{$iteminitem} ";
#   }
#   print "\n";
# }


###############
# # my $avg = &average(\@wordCounts);
# # my $cAvg = &average(\@cWordCounts) if $ctrlFile;
# # 
# # #print $cAvg, "\n" if $ctrlFile;
# # #my $std = &stdev(\@wordCounts);
# # #print $ave, "\t", $std, "\n";
# # 
# # foreach my $key (sort { $wordHash {$b} <=> $wordHash {$a}} keys %wordHash) 
# # {
# #   my $norm = sprintf("%.2f", $wordHash{$key} / $avg);
# # 
# #   print $norm, "\t", $wordHash{$key}, "\t", $key, "\n" unless $ctrlFile; 
# #   
# #   if ($ctrlFile) {
# #     if ( exists $cWordHash{$key} ) {
# # 
# #       my $weightVal = sprintf("%.2f",  $cWordHash{$key} / $cAvg);        
# #       print $weightVal, "\t", $wordHash{$key}, "\t", $key, "\n";
# #       } else {
# #       print "new term", "\t", $wordHash{$key}, "\t", $key, "\n";
# #     }
# #   }
# # }
# # 
# # ### Subroutines ###
# # 
# # sub average{
# #         my($data) = @_;
# #         if (not @$data) {
# #                 die("Empty array\n");
# #         }
# #         my $total = 0;
# #         foreach (@$data) {
# #                 $total += $_;
# #         }
# #         my $average = $total / @$data;
# #         return $average;
# # }
# # 
# # sub stdev{
# #         my($data) = @_;
# #         if(@$data == 1){
# #                 return 0;
# #         }
# #         my $average = &average($data);
# #         my $sqtotal = 0;
# #         foreach(@$data) {
# #                 $sqtotal += ($average-$_) ** 2;
# #         }
# #         my $std = ($sqtotal / (@$data)) ** 0.5;
# #         return $std;
# # }


