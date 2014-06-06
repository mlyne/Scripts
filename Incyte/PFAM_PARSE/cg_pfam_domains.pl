#!/usr/local/bin/perl -w
#
# Takes pfam output e.g. 
# cat *.esthmmpfam | cg_pfam_domains.pl
# and gives back a non-redundant list
# of pfam domains found

use strict;

my @all_pfam_ids = ();
my ($id);
my %count;



$/ = undef;

my @pfam_results = split( m(//\n), <> );

$/ = "\n";

foreach my $a_record ( @pfam_results )
{
    my ($locus, $query, $pfam_id);
    my @domain_hits = ();


  my @split_result = split( m(\n), $a_record );
    my %pfam_hash;

  foreach my $line ( @split_result )
  {

    if ($line =~ /LOCUS\t(.*)/)
    {
      $locus = $1;
    }
    
    if ($line =~ /QUERY\t(.*)/)
    {
      $query = $1;
    }

    if ($line =~ m(([a-zA-Z0-9-_]+)\s+\d/\d+))
    {
      $pfam_id = $1;
#      print "$pfam_id\n";
      chomp $pfam_id;
      push @all_pfam_ids, $pfam_id;
      push @domain_hits, $line;
    }

  }

    if (@domain_hits > 1)
    {
#      print "LOCUS:$locus QUERY:$query\n";
      for my $i (0 .. $#domain_hits)
      {
#	print $domain_hits[$i], "\n";
      }
#      print "\n";
    }


}

foreach $id ( @all_pfam_ids )
{
  $count{$id}++;
}

foreach $id ( sort { $count{$b} cmp $count{$a} } keys %count)
{
#  print "$id: $count{$id}\n";
  print "$id\n";
}
