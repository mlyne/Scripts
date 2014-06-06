#!/usr/local/bin/perl -w
#
#
#

use strict;

my $usage = "Usage:cdslist_2domain_count.pl cdslist_file domain_count_file \n";

unless ( $ARGV[1] ) { die $usage }

my $cds_list = $ARGV[0];
my $count_file = $ARGV[1];

open(LIST_FILE, "< $cds_list")  || die "cannot open $cds_list: $!";
open(COUNT_FILE, "< $count_file")  || die "cannot open $count_file: $!";

my ($pfam_cds, $pfam_count);
my %domain_hash = ();

while (<COUNT_FILE>)
{
  ($pfam_cds, $pfam_count) = split(/\s+/, $_);
  $domain_hash{$pfam_cds} = $pfam_count;
}

close(COUNT_FILE);

my ($locus, $cds, $alt_cds);
my ($line_cds, $line_value);

while (<LIST_FILE>) 
{
  ($locus, $cds, $alt_cds) = split(/\s+/, $_);
  if ((exists $domain_hash{$cds}) 
      && (exists $domain_hash{$alt_cds}))
  {
    if ($domain_hash{$cds} != $domain_hash{$alt_cds})
    {
#      print "$cds\n";
#      print "$alt_cds\n";
      print "Locus:$locus: Cds1:$cds $domain_hash{$cds}\t" .
	  "Cds2:$alt_cds $domain_hash{$alt_cds}\n";
    }
  }
}


close(LIST_FILE);

