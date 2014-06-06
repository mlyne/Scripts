#!/usr/bin/perl

use strict;
use warnings;
#use URI::Escape;
use XML::Twig;
use Data::Dumper;

my $usage = "Usage:parseOrphanetGenes.pl orphanet_geneDis_file.xml

http://www.orphadata.org/data/xml/en_product6.xml

n";

unless ( $ARGV[0] ) { die $usage };

# specify and open query file (format: )
my $xml_file = $ARGV[0];

my $twig = new XML::Twig( twig_handlers => { 'Disorder' => \&process_dis });
$twig->parsefile( "$xml_file" );

sub process_dis {
  my ($twig, $entry) = @_;
  
  my $disorder = $entry->first_child( 'Name' )->text;
  my $geneAssocList = $entry->first_child( 'DisorderGeneAssociationList' );
  my $geneAssoc = $geneAssocList->first_child( 'DisorderGeneAssociation' );
  my @genes = $geneAssoc->children( 'Gene' );
  
  print "Disease ", $disorder, "\n";
  
  foreach my $gene (@genes) {
    my $symbol = $gene->first_child( 'Symbol' )->text;
    print "\t$symbol\n";
    
# #     my @l1 = $section->children( 'diag' );
# #     
# #     foreach my $el1 (@l1) {
# #       my $el1_name = $el1->first_child( 'name' )->text;
# #       my $el1_desc = $el1->first_child( 'desc' )->text;
# # #      print "\t\t", $el1_name, "\t", $el1_desc, "\n";
# #       
# #       my @l2 = $el1->children( 'diag' );
# #       
# #       foreach my $el2 (@l2) {
# # 	my $el2_name = $el2->first_child( 'name' )->text;
# # 	my $el2_desc = $el2->first_child( 'desc' )->text;
# # #	print "\t\t\t", $el2_name, "\t", $el2_desc, "\n";
# # 	print "Ch$chapt", "\t", $name, "\t", $sTitle, "\t", $el1_name, "\t", $el1_desc .
# # 	  "\t", $el2_name, "\t", $el2_desc, "\n";
# #       }
# #     }
  }
  $twig->purge();
}
