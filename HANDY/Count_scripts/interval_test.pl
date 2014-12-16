#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use XML::Twig::XPath;

my $usage = "Usage:int_test.pl int_file1 int_file2\n

Options:
\t-h\tThis help
\t-a\tPrint Authorsl\n
";

unless ( $ARGV[1] ) { die $usage }

### command line options ###
my (%opts, $optAuth);

getopts('ha', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"a"} and $optAuth++;

# Take input from the command line

my $intFile1 = $ARGV[0];
my $intFile2 = $ARGV[1];

open(IFILE1, "< $intFile1") || die "cannot open $intFile1: $!\n";
open(IFILE2, "< $intFile2")  || die "cannot open $intFile2: $!";

my @int2; 

$/ = undef;

while (<IFILE2>)
{
  @int2 = split(/\n/, $_);
}

print "size: ", scalar(@int2), "\n";

# Close the second int file we've opened
close(IFILE2);

$/ = "\n";

while (<IFILE1>)
{
  chomp;
#  my $int = $_;
  my ($ID1, $chr1, $start1, $end1, $strand1, $ID2_1) = split(/\t/, $_);
  print "start1: ", $start1, "\n";
  
  foreach my $entryInt2 (@int2)
  {
    chomp $entryInt2;
    my ($chr2, $start2, $end2, $ID2, $strand1, $len2, $strand2, undef, undef, undef, undef, undef, undef) = split(/\t/, $entryInt2);
    print "start2: ", $start2, "\n";
  }
}

# Close the first int file we've opened
close(IFILE1);



