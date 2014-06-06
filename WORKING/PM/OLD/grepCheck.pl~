#!/usr/bin/perl -w
use strict;
use warnings;

my $usage = "Usage:grepCheck.pl matchTermFile termFile

matchFile format: # \t term

Finds identical matches to a term set in a term freq file\n";

unless ( $ARGV[1] ) { die $usage }

my $tFile1 = $ARGV[0];
my $tFile2 = $ARGV[1];

my %singHash = ();

open(T1_FILE, "< $tFile1") || die "cannot open $tFile1: $!\n";
my @terms;
my %multHash = ();

while (<T1_FILE>) {
  chomp;
  my ($id, $terms) = split(/\t/, $_);
  $multHash{$terms} = $id;
}

close (T1_FILE);

open(T2_FILE, "< $tFile2") || die "cannot open $tFile2: $!\n";


while (<T2_FILE>) {
  chomp;
 
   if ( exists $multHash{$_} )
   {
      print $multHash {$_}, "\t", $_, "\n";
   }
}
close (T2_FILE);
