#!/usr/local/bin/perl -w
#
#
#

use strict;

 READ_LOOP: while (<>) 
{
  chomp $_;
#  print "$_\n";

  my @names = ();
  my @systematic = ();
  my @symbol = ();
  my $name;

  @names = split(/,/, $_);
#  print @names[0], "\n";

    foreach $name (@names) {
#    print "$name\n";
    
    if ($name =~ m/SP[ABC][CP]/) 
    {
      push (@systematic, $name);
#      print "A systematic!\n";
    }
    else 
    {
      push (@symbol, $name); 
#      print "A gene symbol!\n";
    }
  }

  print join(', ', @systematic), "\t";
  print join(', ', @symbol), "\n";

}
