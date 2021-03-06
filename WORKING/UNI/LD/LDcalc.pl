#!/usr/bin/perl
use strict;
use warnings;

my $usage = "Usage: LDcalc.pl pairwiseLD_file\n";
unless ( $ARGV[0] ) { die $usage }

# Take input from the command line

my $ldFile = $ARGV[0];

open(IFILE, "< $ldFile") || die "cannot open $ldFile: $!\n";

my ($count, $cumD);
my %blockID;
my (@block2snp);
my $blockEnd;

while (<IFILE>)
{
  chomp;
  $count++;
  my ($start, $end, $popn, $snp1, $snp2, $dPrime, $rSq, $lod, $box) = split(/ /, $_);

  if (($blockEnd) && ($start <= $blockEnd)) {
    $count = 1;
#    print "$blockEnd\n";
    next;
  }

  my $blockLen = ($end - $start);
  $cumD += $dPrime;
  my $avgD = ($cumD / $count);
  
  push (@block2snp, $snp1);

#  print "First:  $snp1 $start $end $snp2 $blockLen $dPrime $cumD $avgD\n";

  if ($avgD < 0.8) {
    $blockID{$snp1} = [$start, $end, $blockLen, \@block2snp];
    $blockEnd = $blockID{$snp1}->[1];
#    print "$start $blockEnd\n";
#    $blockEnd = $end;
    @block2snp = ();
#    $count = 0;
    $cumD = $dPrime;  ### Where does this go?
    #next until ($start > $blockEnd);
  }

#  if (exists $blockID{$snp1}) {
#    my $blockEnd = $blockID{$snp1}->[1];
#    print $blockEnd, "\n";
#    @block2snp = ();
#    $count = 1;
#    $cumD = $dPrime;  ### Where does this go?
#    next until ($start > $blockEnd);

#  }

#  print "Secnd: ", $snp1, " ", $snp2, " ", $blockLen, " ", $dPrime, " ", $cumD, " ", $avgD, "\n";
}

# Close the file we've opened
close(IFILE);

foreach my $key (keys %blockID) {
  print $key, " ", $blockID{$key}->[0], " ", $blockID{$key}->[1], " ", $blockID{$key}->[2], "\n";
}
