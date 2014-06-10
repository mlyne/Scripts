#!/usr/bin/perl

use strict;
use warnings;
#use URI::Escape;
use XML::Twig;
use Data::Dumper;

my $usage = "Usage:parseICD.pl ICD10CM_FY2014_Full_XML_Tabular.xml
ICD10-CM file in XML
available from:
http://www.cdc.gov/nchs/icd/icd10cm.htm - links to:
wget 
'ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Publications/ICD10CM/2014/ICD10CM_FY2014_Full_XML.zip'

n";

unless ( $ARGV[0] ) { die $usage };

# specify and open query file (format: )
my $xml_file = $ARGV[0];

my $twig = new XML::Twig( twig_handlers => { 'chapter' => \&process_chapt });
$twig->parsefile( "$xml_file" );

sub process_chapt {
  my ($twig, $entry) = @_;
  
  my $chapt = $entry->first_child( 'name' )->text;
  my $name = $entry->first_child( 'desc' )->text;
  my @sections = $entry->children( 'section' );
  
#  print "Chapter ", $chapt, "\t", $name, "\tSections: ", scalar(@sections), "\n";
  
  foreach my $section (@sections) {
    my $sTitle = $section->first_child( 'desc' )->text;
#    print "\t$sTitle\n";
    
    my @l1 = $section->children( 'diag' );
    
    foreach my $el1 (@l1) {
      my $el1_name = $el1->first_child( 'name' )->text;
      my $el1_desc = $el1->first_child( 'desc' )->text;
#      print "\t\t", $el1_name, "\t", $el1_desc, "\n";
      
      my @l2 = $el1->children( 'diag' );
      
      foreach my $el2 (@l2) {
	my $el2_name = $el2->first_child( 'name' )->text;
	my $el2_desc = $el2->first_child( 'desc' )->text;
#	print "\t\t\t", $el2_name, "\t", $el2_desc, "\n";
	print "Ch$chapt", "\t", $name, "\t", $sTitle, "\t", $el1_name, "\t", $el1_desc .
	  "\t", $el2_name, "\t", $el2_desc, "\n";
      }
    }
  }
  $twig->purge();
}
