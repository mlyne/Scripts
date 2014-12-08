#!/usr/bin/perl -w

use strict;
use warnings;

die "Usage: samRemDup.pl sam_file\n" unless @ARGV;
open INFILE, $ARGV[0] or die "Couldn't open infile: $!\n";

my %seen;

while (<INFILE>) {   
  chomp;

  if ($_ =~ /^@\w\w/) {
    print $_, "\n";
    next;
  }

  if ($_ =~ /\tLocus_/) {
    my ($readID, $flag, $seqID, $pos, $maq, $cigar, $mrnm, $mpos, $isize, $seq, $quak, $tags) = split ("\t", $_, 12);
    my ($locus, $transc, $len);
    $seqID =~ /(Locus_\d+)_Transcript_.+?_Length_\d+/;
    $locus = $1;

    my $key = join ':', $locus, $readID;

    if ( $seen{$key} ) {
      next;
    }
    else {
      $seen{$key}++;
      print $_, "\n";
    }
  }


}