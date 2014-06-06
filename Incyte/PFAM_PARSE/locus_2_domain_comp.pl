#!/usr/local/bin/perl -w
#
# Takes a table of Locus, reference_cds,
# alternative_splice_model and uses
# that to cross reference ref_cds_name
# to putative_cds_name to compare numbers
# of pfam domains in two lists.
# 
# Outputs locus info if the ref_cds and 
# alt_splice_cds have a different number
# of domains.
#
# Usage - 

use strict;

my $usage = "Usage:locus_2_domain_comp.pl cdslist_file " .
    "ref_domain_count_file alt_domain_count_file\n";

unless ( $ARGV[2] ) { die $usage }

my $cds_list = $ARGV[0];
my $count_file = $ARGV[1];
my $alt_count_file = $ARGV[2];


my ($locus, $gene_cds, $alt_cds);
my %locus_hash;

open(LIST_FILE, "< $cds_list")  || die "cannot open $cds_list: $!";

while (<LIST_FILE>)
{
  ($locus, $gene_cds, $alt_cds) = split(/\t/, $_);
  $locus_hash{$locus}->{$gene_cds}->{$alt_cds} = undef;
}

close(LIST_FILE);

my %pfam_cds_hash = cds_file($count_file);
my %pfam_alt_hash = alt_file($alt_count_file);

my ($hrLocus, $cds, $hrCDS);
my ($alt, $hrALT);

foreach $locus (sort keys %locus_hash) 
{
  $hrLocus = $locus_hash{$locus};
  while (($cds, $hrCDS) = each (%$hrLocus)) 
  {
    if ( exists($pfam_cds_hash{$cds}) )
    {
      ($alt, $hrALT) =  (%$hrCDS);

      while (($alt, $hrALT) = each (%$hrCDS))
      {
	if ( exists($pfam_alt_hash{$alt}) )
	{
	  if ($pfam_cds_hash{$cds} != $pfam_alt_hash{$alt})
	  {
	    print "Locus:$locus\tCDS:$cds $pfam_cds_hash{$cds}\t" . 
		"Alt:$alt $pfam_alt_hash{$alt}\n";
	  }
	}
      }
    }
  }
}
   

###             ###
### Subroutines ###
###             ###

sub cds_file
{

  my ($ref_file) = @_;

  open (REF_FILE, "< $ref_file")  
      || die "cannot open $ref_file: $!"; 

  my ($pfam_cds, $pfam_cds_val);
  my %pfam_cds_hash = ();

  while (<REF_FILE>)
  {
    ($pfam_cds, $pfam_cds_val) = split(/\s/, $_);
    $pfam_cds_hash{$pfam_cds} = $pfam_cds_val;
  }
  close(REF_FILE);
  return %pfam_cds_hash;
}

sub alt_file
{

  my ($alt_file) = @_;

  open (ALT_FILE, "< $alt_file")  
      || die "cannot open $alt_file: $!"; 

  my ($alt_pfam_cds, $alt_pfam_cds_val);
  my %alt_pfam_cds_hash = ();

  while (<ALT_FILE>)
  {
    ($alt_pfam_cds, $alt_pfam_cds_val) = split(/\s/, $_);
    $alt_pfam_cds_hash{$alt_pfam_cds} = $alt_pfam_cds_val;
  }
  close(ALT_FILE);
  return %alt_pfam_cds_hash;
}
