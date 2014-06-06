#!/usr/bin/perl
use strict;
use warnings;

my $usage = "Usage:extractDrgDis.pl drg_dis_file

\n";

unless ( $ARGV[0] ) { die $usage }

my $inFile = $ARGV[0];

open(IN_FILE, "< $inFile")  || die "cannot open $inFile: $!";

my %rdHits;

while (<IN_FILE>)
{
  chomp;
  my ($dis, $drugs) = split(/\t/, $_);
  
  $dis =~ s/clin_//;
  
  if ($drugs =~ /, /) {
    my @drugs = split(/, /, $drugs);
    foreach my $drug (@drugs) {
      $rdHits{$dis}{$drug}++;
#      print $dis, "\t", $drug, "\n";
    }
  } else {
    $rdHits{$dis}{$drugs}++;
#    print $dis, "\t", $drugs, "\n";
  }
}

close(IN_FILE);

foreach my $disKey (keys %rdHits )
{
  foreach my $drugKey ( sort { $rdHits{$disKey} {$b} <=> $rdHits{$disKey} {$a} } keys %{ $rdHits{$disKey} } )
  {
    print $disKey, "\t", $drugKey, "\t", $rdHits{$disKey}{$drugKey}, "\n";
  }
}
