#!/software/arch/bin/perl
#
#

use Getopt::Long;
use strict;

while (<>) 
{
  chomp;
  my ($locus, $id, $ids) = split("\t", $_);

  if ($id ne "NULL")
  {
    print "Locus : \"$locus\"\n";
    print "FL_id    \"$id\"\n";
  } else {
    next;
  }

  my @ids =  ();

  unless ($ids eq "none")
  {
    if ($ids !~ /\//)
    {
      push(@ids, $ids);
    } 
    else 
    {
      @ids = split("\/", $ids);
    }
  }

  for (@ids)
  {
    print "CA2_id   \"$_\"\n";
  }

  print "\n\n";

}
  
