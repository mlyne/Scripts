#!/usr/local/bin/perl -w

use strict;

undef $/;

my @chunks =();

while (<>) 
{
  chomp;
  @chunks = split(/S2: \d+ \(.+bits\)/, $_);
}


foreach my $chunk (@chunks)
{
  unless ($chunk =~ /No hits found/)
  {
    my $file = $chunk;
    print "$file\n";
  }
}
