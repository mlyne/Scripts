#!/usr/bin/perl

use strict;
use warnings;
#use LWP::UserAgent;
#use HTTP::Request::Common qw/POST/;
#use URI::Escape;
use XML::Twig;
use Data::Dumper;

my $usage = "Usage:script.pl query_file out_file
    

\n";

unless ( $ARGV[0] ) { die $usage }

# specify and open query file (format: )
my $in_file = $ARGV[0];
#my $outFile = $ARGV[1];

#open(IFILE, "< $in_file") || die "cannot open $in_file: $!\n";
#open(OUT_FILE, "> $outFile") || die "cannot open $outFile: $!\n";

\handler($in_file)

# while (<IFILE>)
# {
#   chomp;
# 
#   my $respRef = ops_post($query, $range);
# 
#   
# 
# }

\close(IFILE);


sub handler {

  my $file = shift;
#  my $file = $$resRef;
  my $twig = new XML::Twig( twig_handlers => { 'Entrezgene_locus' => \&process_geneComment });
  $twig->parsefile( $file );

}

sub process_geneComment {
  my ($twig, $entry) = @_;
  
#  print Dumper ($twig);
  
#  my $fam = $entry->att( 'Gene-commentary');
  
  my @genComms = $entry->descendants('Gene-commentary');
  
  foreach my $comRef (@genComms) {
    my $rifRef = $comRef->first_descendant('Gene-commentary_type[@value="generif"]') if $comRef;
    my $rifCom = $comRef->first_descendant('Gene-commentary_text')->text  if $rifRef;
    my $pmid = $comRef->first_descendant('PubMedId')->text  if $rifRef;

    print "rif: ", $rifCom, "\t:\t$pmid\n" if ($rifCom && $pmid);
  }

#   my @ipcList = $entry->descendants('/classification-ipc\b/');
# 
#  foreach my $ipc (@ipcList) {
#   print OUT_FILE "IPC: ", $ipc->first_descendant('text')->text, "\n" if $ipc;
#   }
#   
#   my $title = $entry->first_descendant('invention-title')->text;
#   print OUT_FILE "Title: ", $title, "\n";
#   
#   my @applicants = $entry->descendants('applicants');
#   
#   foreach my $applicants (@applicants) {
#     my $applicant = $applicants->first_descendant('applicant[@data-format="epodoc"]') if $applicants;
#     my $app = $applicant->first_descendant('applicant-name')  if $applicant;
#     print OUT_FILE "Applicant: ", $app->first_descendant('name')->text, "\n" if $app;
#   }
#   
# #  my @inventors = $entry->descendants('inventors');
#   my @inventors = $entry->descendants('inventor[@data-format="epodoc"]');
#   
#   foreach my $inventors (@inventors) {
# #    print $inventors, "\n";
# #    my $invenType = $inventors->first_descendant('inventor[@data-format="epodoc"]');
# #    my $invenTag = $invenType->first_descendant('inventor-name');
#     my $invenTag = $inventors->first_descendant('inventor-name') if $inventors;
#     print OUT_FILE "Inventor: ", $invenTag->first_descendant('name')->text, "\n" if $invenTag;
#   }
#   print OUT_FILE "--- END Patent ---\n\n";
#   $twig->purge();
}