#!/usr/bin/perl -w
#
# Parses the output from HMM/ESTHMM
# Pfam
#
# Usage: all_pfam_domains.pl HMM_file 
#

use strict;
use warnings;

my ($id, $domain);
my (%idHash, %tfHash);

 READ_LOOP: while (<>)
{
  chomp;
  ($id, $domain) = split(/\s/, $_);
#  $clone_id =~ s/(\d+)\.\d+/$1/;
  $tfHash{$domain}++;
  push( @{$idHash{$id}}, $domain );
} 

my @tfSort = (sort keys %tfHash);

print "TFsite\t";

print join("\t", @tfSort), "\n";

foreach $id (sort keys %idHash) {
  print $id;

  foreach my $tf (@tfSort) {
#    my $true = grep(m/$tf/, @{$idHash{$id}});
    my $true = grep { lc($_) eq lc($tf) } @{$idHash{$id}};
    if ($true) {
      print "\t1";
    } else { print "\t0"}
  }

print "\n";

}

