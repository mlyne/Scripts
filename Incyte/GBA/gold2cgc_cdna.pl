#!/usr/local/bin/perl -w
#
#
#

use strict;

my $lg_id;
my @results;
my $top_hit;
my @result_array;
my $db_locus;
my $locus;

while (<>)
{
  chomp;
  $lg_id = $_;
  @results = ();
  @results = `echo $lg_id | lt_retrieve /d2/databases/incyte/Gold | blastall -p blastn -d cgc_cdna -i stdin | MSPcrunch -d -I 95 - | sort -nr`;
  if (@results)
  {
    $top_hit = shift(@results);
    chomp $top_hit;
    @result_array = split(/\s+/, $top_hit); 
    $db_locus = $result_array[-1];
    $db_locus =~ s/_link_cdna//g;
    print "$lg_id\t$db_locus\n";
  }

}



