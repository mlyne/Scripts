#!/usr/bin/perl

use strict;
use warnings;
#use LWP::UserAgent;
#use HTTP::Request::Common qw/POST/;
#use URI::Escape;
use XML::Twig;
use Data::Dumper;

my $usage = "Usage:epo_patent.pl query_file out_file
    
    
n";

unless ( $ARGV[0] ) { die $usage }

# specify and open query file (format: )
my $query_file = $ARGV[0];

  my $out = $query_file;
  my $valid = "true" if ($out =~ m/search-result/);

# Then use grep to retrieve the line with reference info
# feed into $entry

  my ($hitCount) = defined $valid ? ($out =~ m/biblio\-search total\-result\-count\=\"(\d+)\"/) : ("12321");
  print "Count: ", $hitCount, "\n";
 
#  print $out;
 
  my $root = new XML::Twig( twig_handlers => { 'exchange-document' => \&process_patRes });
  $root->parsefile( $out );
#  $twig->parse( $out );  
 
 # Output the entry
# print $response->content();
  
  # To comply with fair use policy
#  sleep(5);
# select(undef, undef, undef, 5); # EPO requires that we have no more than 10 requests / minute so delay 5 secs

#close(QFILE);


sub process_patRes {
  my ($twig, $entry) = @_;
  
#  print Dumper ($twig);
  
  my $fam = $entry->att( 'family-id');
  print "Fam: ", $fam, "\n";

  my @ipcList = $entry->descendants('/classification-ipc/');

 foreach my $ipc (@ipcList) {
  print "ipc: ", $ipc->first_descendant('text')->text, "\n";
  }
  
  my $title = $entry->first_descendant('invention-title')->text;
  print "Title: ", $title, "\n";
  
# <applicant sequence="1" data-format="epodoc"><applicant-name><name>ARAKIS LTD</name>

  my @applicants = $entry->descendants('applicants');
#  applicant[@data-format="epodoc"]
  
#  print Dumper (@applicants);
  
  foreach my $applicants (@applicants) {
    my $applicant = $applicants->first_descendant('applicant[@data-format="epodoc"]');
    my $app = $applicant->first_descendant('applicant-name');
    print "Applicant: ", $app->first_descendant('name')->text, "\n";
  }
  
#  my @inventors = $entry->descendants('inventors');
  my @inventors = $entry->descendants('inventor[@data-format="epodoc"]');
  
  foreach my $inventors (@inventors) {
#    print $inventors, "\n";
#    my $invenType = $inventors->first_descendant('inventor[@data-format="epodoc"]');
#    my $invenTag = $invenType->first_descendant('inventor-name');
    my $invenTag = $inventors->first_descendant('inventor-name');
    print "Inventor: ", $invenTag->first_descendant('name')->text, "\n";
  }


}