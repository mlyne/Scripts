#!/usr/bin/perl -w
#
# Parses the output from HMM/ESTHMM
# Pfam
#
# Usage: all_pfam_domains.pl HMM_file 
#

use strict;

my ($cat_id, $field);
my %id_hash = ();

 READ_LOOP: while (<>)
{
	chomp;
  ($cat_id, $field) = split(/\t/, $_);
#  $clone_id =~ s/(\d+)\.\d+/$1/;

  push( @{$id_hash{$cat_id}}, $field );
}

foreach $cat_id (sort keys %id_hash) {
  print "$cat_id\t@{$id_hash{$cat_id}}\n";
#  	my $sum += @{$id_hash{$cat_id}};
#	print "$sum\n";
}

