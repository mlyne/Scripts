#!/usr/local/bin/perl -w
#
# 
#

use Getopt::Long;
use strict;

my $usage = "Usage: tablejoiner.pl [--help] 

tablejoiner.pl --first <number> --second <number> [--output <number>] file1 file2

Takes two files and executes a join.

Output format can be specified using the 
--output <number> option for each column
e.g. --output 1 --output 2 etc.
Default output is: 1 2 3 4

file1 & file2 must have a sorted equivalent 
column to join on!

\t--help help (this list)
\t--first column of file1 to join on (1 or 2 or 3 etc.)
\t--second column of file2 to join on (as above)
\t--output column to print (1-4)

\n";

unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts, $join1, $join2, @output);

GetOptions(\%opts, 'help', 'first=i', 'second=i', 'output=i@');
defined $opts{"help"} and die $usage;

defined $opts{"first"} and $join1 = $opts{"first"};
defined $opts{"second"} and $join2 = $opts{"second"};
defined $opts{"output"} and @output = @{$opts{"output"}};

if (@output)
{
  for my $testval (0 .. $#output)
  {
    die $usage if (($output[$testval] < 1) 
		   || ($output[$testval] > 4));
  }
}

### script body ###
my $file1 = $ARGV[0];
my $file2 = $ARGV[1];

open(JOIN, "join -1 $join1 -2 $join2 $file1 $file2 |") 
    or die "Couldn't fork: $!\n";

while (<JOIN>) 
{
  chomp;
  my ($column1, $column2, $column3, $column4) = split(/\s/, $_, 4);
  if (@output)
  {
    for my $i (0 .. $#output)
    {
      print "$column1\t" if ($output[$i] == 1);
      print "$column2\t" if ($output[$i] == 2);
      print "$column3\t" if ($output[$i] == 3);
      print "$column4\t" if ($output[$i] == 4);
    }
    print "\n";
  }
  else
  {
    print "$column1\t$column2\t$column3\t$column4\n";
  }
}

