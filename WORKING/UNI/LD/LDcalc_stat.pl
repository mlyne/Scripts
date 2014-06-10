#!/usr/bin/perl
use strict;
use warnings;
use Statistics::Descriptive;

my $usage = "Usage: LDcalc.pl pairwiseLD_file\n";
unless ( $ARGV[0] ) { die $usage }

# Take input from the command line

my $ldFile = $ARGV[0];

open(IFILE, "< $ldFile") || die "cannot open $ldFile: $!\n";

my ($count, $cumD);
my %blockID;
my (@block2snp, @clearStats);
my $blockEnd;
my ($mean, $std);

my $stat = Statistics::Descriptive::Full->new();

while (<IFILE>)
{
  chomp;
  $count++;
  my ($start, $end, $popn, $snp1, $snp2, $dPrime, $rSq, $lod, $box) = split(/ /, $_);

  $stat->add_data($dPrime);

  if (($blockEnd) && ($start <= $blockEnd)) {
    $count = 1;
#    @block2snp = ();
    $stat->clear();
    next;
  }

  my $blockLen = ($end - $start);
  
  push (@block2snp, $snp2);

  $mean = $stat ? ($stat->mean()) : 1e-27;
  $std = $stat ? ($stat->standard_deviation()) : 1e-27;

  if ($std < 0.2) {
    $blockID{$snp1} = [$start, $end, $blockLen, [@block2snp]];
#    print $snp1, " ", $blockID{$snp1}->[0], " ", $blockID{$snp1}->[1], " ", $blockID{$snp1}->[2], " SNPs: ", join(",", @{$blockID{$snp1}->[3]}), "\n";
#    print " SNPs: ", join(",", @{$blockID{$snp1}->[3]}), "\n";

  } else {
    $count = 1;
    $stat->clear();
    $blockEnd = $end;
    @block2snp = ();
    next;
#    next until (! exists $blockID{$snp1});
}

#  print "Stats: $dPrime $snp1 $snp2  $mean $std   $blockLen\n\n";
#  print " SNPs: ", join(",", @{$blockID{$snp1}->[3]}), "\n";
}

# Close the file we've opened
close(IFILE);

foreach my $key (keys %blockID) {
#foreach my $key ( sort { $blockID{$a}[0] <=> $blockID{$b}[0] } keys %blockID) {
  print $key, " ", $blockID{$key}->[0], " ", $blockID{$key}->[1], " ", $blockID{$key}->[2], " SNPs: ", join(",", @{$blockID{$key}->[3]}), "\n";
#  print join(",", @{$blockID{$key}->[3]}), "\n";
}




####### Scratch #######

#  $cumD += $dPrime;
#  my $avgD = ($cumD / $count);

#   if ($std > 0.2) {
#     $blockID{$snp1} = [$start, $end, $blockLen, \@block2snp];
#     $blockEnd = $blockID{$snp1}->[1];
#     $stat->clear();
#     @block2snp = ();
# }


#  if ($avgD < 0.8) {
#    $blockID{$snp1} = [$start, $end, $blockLen, \@block2snp];
#    $blockEnd = $blockID{$snp1}->[1];
#    @block2snp = ();
#    $cumD = $dPrime;  ### Where does this go?
#    $stat->clear();
#  }

