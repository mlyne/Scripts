#!/usr/local/bin/perl -w
#
# Works on output from EST/HMM pfam
# to give non-redundant domain content
# of query seq
#
# Usage: representative_pfam_domains.pl HMM_FILE

use strict;

my ($bin_id, $domain, $p_val, $e_val);
my %id_hash;

 READ_LOOP: while (<>)
{
  ($bin_id, $domain, $p_val, $e_val) = split(/\s+/, $_);
  $bin_id =~ s/(\d+)\.\d+/$1/;

  $id_hash{$bin_id}->{$domain} = undef;

}

my $hrBin;

foreach $bin_id (sort { $a cmp $b } keys %id_hash) {
  $hrBin = $id_hash{$bin_id};
  print "$bin_id\t";
  print join(' ', keys %$hrBin);
  print "\n";
}

