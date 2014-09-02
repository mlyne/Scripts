#!/usr/bin/perl 
use strict;
use warnings;

my $usage = "Usage:combineTermsRE.pl termFile termFile

Use: takes two files of search terms and combines into one search
term using AND operator.

File format: ID \t (search terms)

\n";

unless ( $ARGV[1] ) { die $usage }

my $t1File = $ARGV[0];
my $t2Files = $ARGV[1];

open(T1_FILE, "< $t1File") || die "cannot open $t1File: $!\n";
$/=undef;

my @t1;
while (<T1_FILE>) {
  @t1 = split(/\n/, $_);
}

close (T1_FILE);

open(T2_FILE, "< $t2Files") || die "cannot open $t2Files: $!\n";

$/= "\n";

while (<T2_FILE>) {
  chomp;
  my ($id2, $term2) = split(/\t/, $_);

  foreach my $term (@t1)
  {
  chomp;
  my ($id, $term1) = split(/\t/, $term);
  print $id, "_", $id2, "\t", "\(", $term1, " AND ", $term2, "\)\n";
  }
}
close (T2_FILE);
