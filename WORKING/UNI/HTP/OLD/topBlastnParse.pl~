#!/usr/bin/perl

use strict;
use warnings;
use LWP::Simple;
use XML::Twig;
#use Getopt::Std;

### command line options ###
# my (%opts, $cutoff);
# 
# getopts('hdtm', \%opts);
# defined $opts{"h"} and die $usage;
# defined $opts{"c"} and $cutoff++;

# start timer
#my $start = time();

my $blastn_results_file = $ARGV[0];    #FASTA
my $out_file = $ARGV[1];

#$uniprot_file = $ARGV[1];

my $usage = "Usage: topBlastnParse_uniP.pl blastn_results_file out_file
blastResultsFile in tab format #6: transcriptID \t transcriptID2 \t ... values ... \t e-val etc
\n";
unless ( $ARGV[1] ) { die $usage }

open IN, "$blastn_results_file" or die "can't open file";
open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";

my %topHit = ();

while (<IN>) {
  chomp $_;
  my @split = split( /\t/, $_ );
  $split[0] =~ /^(Locus_\d+)_Tran/;
  my $evalue = $split[10];
  my $locus  = $1;

  $split[1] =~ /^(Locus_\d+)_Tran/;
  my $locus2 = $1;

  if ( (exists $topHit{$locus}) && ($evalue > $topHit{$locus}->[0]) ) {
    next;
  } else {
    $topHit{$locus} = [$evalue, $locus2];
  }

}
close IN;

foreach my $entry ( keys %topHit ) {

  my $eval = "$topHit{$entry}->[0]";
  my $loc2 = "$topHit{$entry}->[1]";

  next unless ($eval < 0.00001);
    #print $entry, "\t", join("\t", @{ $topHit{$entry} } ), "\n";
  print OUT_FILE $entry, "\t", $loc2, "\t", $eval, "\n";
}

close OUT_FILE;
