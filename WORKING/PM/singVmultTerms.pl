#!/usr/bin/perl -w
use strict;
use warnings;

my $usage = "Usage:singVmult.pl singTermFile multTermFile\n";

unless ( $ARGV[1] ) { die $usage }

my $singFile = $ARGV[0];
my $multFiles = $ARGV[1];

open(SING_FILE, "< $singFile") || die "cannot open $singFile: $!\n";

my %singHash = ();

while (<SING_FILE>) {
  chomp;
  $singHash{$_}++;
}

open(MULT_FILE, "< $multFiles") || die "cannot open $multFiles: $!\n";
my @words;
my %multHash = ();

while (<MULT_FILE>) {
  chomp;
  @words = split / /, $_;
  foreach my $word (@words)
  {
    $multHash{$word}++;
  }
}
close (MULT_FILE);

foreach my $key (sort { $singHash {$b} <=> $singHash {$a}} keys %singHash) 
{
   if ( exists $multHash{$key} )
   {
      print $key,"\t", "FOUND","\n";
   } else {
      print $key,"\t", "NEW","\n";
   }
}

