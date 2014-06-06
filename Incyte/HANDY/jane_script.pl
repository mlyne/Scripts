#!/usr/local/bin/perl -w
#
#
#

use strict;
use FileHandle;

STDOUT->autoflush (1);
STDERR->autoflush (1);

my $parse_file =  pop(@ARGV);
my $pattern_file = $ARGV[0];

open(PARSE, "< $parse_file") or die "Couldn't open $parse_file: $!\n";

my $line;
my @line = ();

while (<PARSE>)
{
  chomp;
  $line = $_; 
  push(@line, $line);
}
 
close(PARSE) or die "Couldn't close $parse_file: $!\n";

open(PATTERN, "< $pattern_file") or die "Couldn't open $pattern_file: $!\n";

my ($col1, $col2, $col3, $col4, $col5, $col6, $col7, $col8, $col9,
    $col10, $col11, $col12, $col13, $col14);
 
while (<PATTERN>)
{
  chomp;
  my $expr = "$_";

  foreach my $i (@line)
  {
#    print "$i\n";
    
    ($col1, $col2, $col3, $col4, $col5, $col6, $col7, $col8, $col9,
     $col10, $col11, $col12, $col13, $col14) = split(/\t/, $i);

#    print "$col4\n";

    if (($col4 =~ /\b$expr/) && ($col4 !~ /$expr\d+/))
    {
      print "$col1\t$col2\t$col3\t$col4\t$col5\t$col6\t$col7\t$col11\t$col12\t$col13\t$col14\n";
    }
  }
	
}

close(PATTERN);

