#!/usr/local/bin/perl -w
#
#
#

use Getopt::Std;
use strict;

my $usage = "Usage:list_parse.pl [-h] [-c] list_file >! outfile

\t-h help -usage
\t-c if list is in column form 
\t   (default file rows)
\n";

unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts, $column);

getopts('hc', \%opts);

defined $opts{"h"} and die $usage;
defined $opts{"c"} and $column++;

### script body ###
my $infile = $ARGV[0];

open(INFILE, "< $infile") || die "cannot open $infile: $!";

my ($line);
my @entries = ();
my @newlist = ();
my ($entry);

while (<INFILE>)
{
  chomp;
  @entries = split /\s/, $_ unless $column;
  push (@entries, $_) if $column;
}

foreach $entry (@entries)
{
  $line = "\'$entry\'";
  push (@newlist, $line);
}

print "(", join(', ', @newlist), ")";


