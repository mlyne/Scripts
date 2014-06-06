#!/usr/bin/perl

use strict;
use warnings;
use XML::Twig::XPath;
#use Data::Dumper;

my $usage = "Usage:geneRIFs.pl geneRIF_file.xml

\n";

unless ( $ARGV[0] ) { die $usage }

# specify and open query file (format: )
my $in_file = $ARGV[0];

  my $twig = new XML::Twig::XPath( twig_handlers => { 'Entrezgene_comments' => \&process_geneComment });
  $twig->parsefile( $in_file );


sub process_geneComment {
  my ($twig, $entry) = @_;
  
#  print Dumper ($entry);

  my @genComms = $entry->findnodes('./Gene-commentary');
  my $cnt = @genComms;
#  print $cnt, "\n";
  
  foreach my $comRef (@genComms) {

    next unless ($comRef->first_child( 'Gene-commentary_type[@value="generif"]' ));
    next if $comRef->first_child_text('Gene-commentary_heading');
#    print $comRef->text, "\n";

    if ( $comRef->first_child_text('Gene-commentary_text') ) {
    print "TAS: ", $comRef->first_child_text('Gene-commentary_text');
    } 

    my $pmids = $comRef->first_descendant('Pub_pmid');
    print "\tPMID:", $pmids->first_descendant('PubMedId')->text, "\n";
  }

   $twig->purge();
}
