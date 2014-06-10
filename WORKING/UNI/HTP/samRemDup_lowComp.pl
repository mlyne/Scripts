#!/usr/bin/perl -w

use strict;
use warnings;

die "Usage: samRemDup.pl sam_file\n" unless @ARGV;
open INFILE, $ARGV[0] or die "Couldn't open infile: $!\n";

my %seen;

while (<INFILE>) {   
  chomp;

  my $aCont;

  if ($_ =~ /^@\w\w/) {
    print $_, "\n";
    next;
  }

  if ($_ =~ /\tLocus_/) {
    my ($readID, $flag, $seqID, $pos, $maq, $cigar, $mrnm, $mpos, $isize, $seq, $quak, $tags) = split ("\t", $_, 12);
    my ($locus, $transc, $len);
    $seqID =~ /(Locus_\d+)_Transcript_.+?_Length_\d+/;
    $locus = $1;

    next if ($flag > 180);

    $aCont = calcgc2( \$seq );

    #print "PANTS: $gcCont\n";

     if ($aCont > 80) {
#       print "PANTS: $aCont $seq\n";
       next;
     }

    my $key = join ':', $locus, $readID;

    if ( $seen{$key} ) {
      next;
    }
    else {
      $seen{$key}++;
#      print "GOOD: $aCont $seq\n";
     print $_, "\n";
    }
  }
}

sub calcgc2 {
  my $seqRef = shift;
  my $seq = $$seqRef;

#  print "SEQ:", $seq, "\t";

  my $count = 0;
  my $len = length($seq);
#  $count = (tr/GC/GC/ =~ $seq); # didn't work, seemed to eval as 0 or 1
#  $count++ while ($seq =~ m/[GCT]/gi); # for %gc
  $count++ while ($seq =~ m/[A]/gi);
  my $num = $count / $len;

#  print "LEN:$len CNT:$count NUM:$num\n";

  my $aVal = sprintf("%.1f",$num * 100);
  return $aVal;

}
