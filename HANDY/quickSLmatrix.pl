#!/usr/bin/perl -w

use strict;

print "Name\tColSearch\tTest\n";
print "RowSearch\tSearch\tTest\n";

while (<>)
{
  chomp;
  print $_, "\t", $_, "[tiab]", "\t", "1\n";
}
