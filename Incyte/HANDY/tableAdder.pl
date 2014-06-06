#!/software/arch/bin/perl -w
#
#
#


use strict;
use Getopt::Std;

my $usage = "Usage:add2table.pl [-t <int>] [-f <int>] [-m <int>] table file\n
Description:
Takes two tab-delimited tables as input.
Where two tables share a common column it will add a column from the 2nd table 
to the first. Default is to compare the first column of both and add the second
column to the first.\n
Options:
\t-t <int>\ttable column for comparison [1..n]
\t-f <int>\tfile column for comparison [1..n]
\t-m <int>\tfile column to add to table [1..n]\n
";


### command line options ###
my (%opts, $table_col, $file_col, $merge);

getopts('ht:f:m:', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"t"} and $table_col = ($opts{"t"} -1);
defined $opts{"f"} and $file_col = ($opts{"f"} -1);
defined $opts{"m"} and $merge = ($opts{"m"} -1);

$table_col ||= 0;
$file_col ||= 0;
$merge ||= 0;

my ($table, $file);

$table = $ARGV[0];
$file = $ARGV[1];

($file) or die $usage;

open(TABLE, "< $table") or die "Couldn't open $table: $!\n";
open(FILE, "< $file") or die "Couldn't open $file: $!\n";

chomp(my @file = (<FILE>));  
my @array;
my $table_len; 


while (<TABLE>) {
  chomp;
  my @fields = split("\t", $_);
  $table_len = scalar(@fields);
  $table_col <= $table_len or die "Column length ", ($table_col +1), " too high!\n";

  for(@file) {
    my @column = split("\t", $_);
    $file_col <= @column or die "Column length ",  ($file_col +1), " too high!\n";
    if ($column[$file_col] eq $fields[$table_col]) {
      push (@fields, $column[$merge]);

    }
  }
  push(@array, [ @fields ]);
}

for (@array) {

  if (@$_ >  $table_len) {
    print join("\t", @$_), "\n";
  }
  else { print join("\t", @$_), "\tnone\n"; 
  }
}
  
