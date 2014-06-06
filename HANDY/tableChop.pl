#!/usr/bin/perl
#
#

use Getopt::Long;
use strict;

my $usage = "Usage: tableChop.pl [-o <int>] file

Description:
Takes a tab separated table and outputs columns
of choice in order of choice.

Exmaple:
\ttableChop.pl -o 1 -o 4 -o 3 file

Prints a tab-separated table of columns 1, 3 & 4
of \"file\"\.
\n";

### command line options ###
my (%opts, @columns);

GetOptions(\%opts, 'help', 'output=i@');
defined $opts{"help"} and die $usage;

defined $opts{"output"} and @columns = @{$opts{"output"}};

my @results = ();

if (@columns)
{
  while (<>) 
  {
    chomp;
    my @array = split("\t", $_);
    my @output = ();
    for my $number (@columns)
    {
      if ($number > 0 && $number <= scalar(@array))
      {
	push(@output, $array[$number -1]);
      }
      else { die $usage }
    }
    push(@results, [ @output ]);
  }
}
else { die $usage }

for (@results) {
  print join( "\t", @{ $_ } ), "\n";
}
