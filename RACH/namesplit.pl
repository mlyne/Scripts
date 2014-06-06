#!/usr/local/bin/perl -w
#
#
#

#$usage = "Usage:namesplit.pl file_to_split";

 READ_LOOP: while (<>) 
{
 
  chomp $_;
  print "$_\n";

  @names = ();
  @systematic = ();
  @symbol= ();

  @names = split(/,/, $_);

  foreach $name (@names) {

    print "$name\n";

    if ($name =~ m/SP[ABC][CP]/) 
    {
      print "A systematic!\n";
      push (@systematic, $name);
    }
    else 
    { 
      print "A gene symbol!\n";
      push (@symbol, $name); 
    }
  }

#    print join(', ', @symbol), "\n";
    print join(', ', @systematic), "\n";

  next READ_LOOP;

} 

