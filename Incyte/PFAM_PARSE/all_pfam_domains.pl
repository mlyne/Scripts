#!/usr/local/bin/perl -w
#
# Parses the output from HMM/ESTHMM
# Pfam
#
# Usage: all_pfam_domains.pl HMM_file 
#

use strict;

my ($clone_id, $domain, $p_val, $e_val);
my %id_hash = ();

 READ_LOOP: while (<>)
{
  ($clone_id, $domain, $p_val, $e_val) = split(/\s+/, $_);
#  $clone_id =~ s/(\d+)\.\d+/$1/;

  push( @{$id_hash{$clone_id}}, $domain );
}

foreach $clone_id (sort keys %id_hash) {
  print "$clone_id\t@{$id_hash{$clone_id}}\n";
}

