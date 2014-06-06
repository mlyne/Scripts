#!/usr/bin/perl
use strict;
use warnings;

my $usage = "Usage: classifyPMdrugsByYr.p drugsByYr_matrix

Takes a 2mode matrix of drugs vs. years and classifies according to:
Popularity: Strong(S), MED(M), Weak(W) and veryWEAK(vW) by counts
Spatial: ALL, (E)arly, (M)id, (L)ate and variations - by year coverage
Trend: (R)ising, (F)alling, (N)one

Options:
\t-h\tThis help
\n";

unless ( $ARGV[0] ) { die $usage }

### command line options ###
# my (%opts, $noMesh, $meshStyle);
# 
# getopts('hns', \%opts);
# defined $opts{"h"} and die $usage;
# defined $opts{"n"} and $noMesh++;
# defined $opts{"s"} and $meshStyle++;


# Take input files from the command line
my $drgHits_file = $ARGV[0];

open DRUGHITS_IN, "$drgHits_file" or die "can't open $drgHits_file\n";

while (<DRUGHITS_IN>) {
  chomp $_;
  my $line = lc($_);
  my @hits = split("\t", $line);
  my $drug = shift(@hits);
  my $drugRE = shift(@hits);
  my $arrlen = (@hits);
  
  my $sum = 0;
  my $avg = 0;
  my $earlyYrs = 0;
  my $medYrs = 0;
  my $lateYrs = 0;
  
  foreach my $ent (@hits) {
    $sum = $sum + $ent if $ent;
#    print "$drug\t$drugRE\t$sum\t$arrlen\n";
  }
  
  $avg = ($sum / $arrlen);
  my $avg_2 = sprintf("%.2f", $avg);
  
  for my $i (0..9) {
    $earlyYrs = ($earlyYrs + $hits[$i]);
#    print $hits[$i], "\n" if $hits[$i];
  }
  
  for my $i (10..28) {
    $medYrs = ($medYrs + $hits[$i]) if $hits[$i];
#    print $hits[$i], "\n" if $hits[$i];
  }
 
  for my $i (29..38) {
    $lateYrs = ($lateYrs + $hits[$i]) if $hits[$i];
#    print $hits[$i], "\n" if $hits[$i];
  }
  
  my $eAv = ( $earlyYrs / 10 );
  my $mAv = ( $medYrs / 20 );
  my $lAv = ( $lateYrs / 10 );
  
  print "$drug\t$drugRE";
  
  if ( !$eAv && !$mAv && !$lAv ) {
    print "\tABS\t$avg|$eAv*$mAv*$lAv\n";
    next;
  }
  
  if ($eAv > 100 || $mAv > 100 || $lAv > 100) {
    print "\tS";
  }
  elsif ($avg < 1) {
    print "\tvW";
  }
  elsif ($eAv < 10 && $mAv < 10 && $lAv < 10) {
    print "\tW";
  }
  else { print "\tM"; }
  
  if ( $eAv && $mAv && $lAv ) {
    print "\tALL";
    if ( ($eAv > $mAv) && ($eAv > $lAv) ) {
      print "\tE\tF";
    }
    elsif ( ($mAv > $eAv) && ($mAv > $lAv) ) {
      print "\tM\tF";
    }
    elsif ( ($lAv > $eAv) && ($lAv > $mAv) ) {
      print "\tL\tR";
    }
  } else { print "\tPART"; }
  
  my $eRatio = ($avg && $eAv) ? ($eAv / $avg) : 0;
  my $mRatio = ($avg && $mAv) ? ($mAv / $avg) : 0;
  my $lRatio = ($avg && $lAv) ? ($lAv / $avg) : 0;
  
  my $eRatio_2 = ($eRatio) ? sprintf("%.2f", $eRatio) : 0;
  my $mRatio_2 = ($mRatio) ? sprintf("%.2f", $mRatio) : 0;
  my $lRatio_2 = ($lRatio) ? sprintf("%.2f", $lRatio) : 0;
  

  print "\tE\tN" if (!$mRatio && !$lRatio);
  print "\tM\tN" if (!$eRatio && !$lRatio);
  print "\tL\tN" if (!$eRatio && !$mRatio);

#  print "\tE_M" if ($eRatio && $mRatio && !$lRatio);
#  print "\tM_L" if (!$eRatio && $mRatio && $lRatio);
  
  if ($eRatio && $mRatio && !$lRatio) {
    print "\tE_M";
    if ($eRatio < $mRatio) {
      print "\tR";
    }
    elsif ($eRatio > $mRatio) {
      print "\tF";
    } else { print "\tN"; }
  }
  
  if (!$eRatio && $mRatio && $lRatio) {
    print "\tM_L";
    if ($mRatio < $lRatio) {
      print "\tR";
    }
    elsif ($mRatio > $lRatio) {
      print "\tF";
    }
  }
  
#  print "\t$avg $eAv $mAv $lAv\n";
  print "\t$avg_2|$eAv*$mAv*$lAv\n";

#if ($eAv > 100 || $mAv > 100 || $lAv > 100);

#print "STRONG: $drug\t$drugRE\t$avg\t$eAv\t$mAv\t$lAv\n" if ($eAv > 100 || $mAv > 100 || $lAv > 100);
}

close (DRUGHITS_IN);



