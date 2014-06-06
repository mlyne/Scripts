#!/usr/local/bin/perl -w
#
# 
# Usage: swap.pl swap_file file >! new_file
# two column space-separated swap_file,
# exchanges the two values in file e.g. 
# if you want to swap acc for locus_id
# in a fasta file
# swap file: GB:123456 Pants
# >GB:123456 -> >Pants

use Getopt::Std;
use strict;

my $usage = "Usage:swap.pl [-h] swap_file file >! new_file
\t-h help
\t-r reversed swap file
two column space-separated swap_file
exchanges the two values in file e.g.
if you want to swap acc for locus_id
in a fasta file...
swap file: GB:123456 Pants
>GB:123456 -> >Pants
";

### command line options ###
my (%opts, $reverse);

getopts('hr', \%opts);
defined $opts{"h"} and die $usage;

defined $opts{"r"} and $reverse++;

my $list = $ARGV[0];
my $file = $ARGV[1];
my @swap;


open (LIST, "< $list") || die "cannot open $list: $!\n";
while (<LIST>)
{
  chomp;
  push(@swap, $_);
}

close (LIST) || die "cannot close $list: $!\n";

my ($val1, $val2);
my $line;

open (FILE, "< $file") || die "cannot open $file: $!\n";

while (<FILE>)
{
  $line = $_;
  foreach my $i (@swap)
  {
    ($val1, $val2) = split(/\s/, $i);
    $line =~ s/$val1\b/$val2/g unless $reverse;
    $line =~ s/$val2\b/$val1/g if $reverse;
  }
  print "$line";
}

close (FILE) || die "cannot close $file: $!\n";
