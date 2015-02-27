#!/usr/bin/perl

use strict;
use warnings;
require LWP::UserAgent;
use XML::Twig;

use feature ':5.12';

my $query = "aff:\"king's college london\"";
my $respRef = &gist( $query );
&pages( $respRef );

exit(1);

sub gist {

my ($query, $page_no) = @_;
my $page_q = "&page=$page_no" if ($page_no);

my $base = "http://plus.europepmc.org/GristAPI/rest/get/query=";
#my $query = "aff:london & pi:peakman";
my $format = "&resultType=core";
my $url = ($page_no) ? ($base . $query . $format . $page_q) : ($base . $query . $format);
#say $url;

my $agent = LWP::UserAgent->new;

my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);

$response->is_success or say "Error: " . 
$response->code . " " . $response->message;

my $content = $response->content;
return \$content if ($content);
#say $content;

}

sub pages {

  my $respRef = shift;
  my $response = $$respRef;
  my $twig = new XML::Twig( twig_handlers => { 'Response' => \&get_pages });
  $twig->parse( $response );

}

sub get_pages {
  my ($twig, $entry) = @_;

  my $entries = $entry->first_child('HitCount')->text if ( $entry->first_child('HitCount') );
  my $pageCalc = int($entries / 25);
  my $pages = ($pageCalc >= 1) ? $pageCalc : 1;
#  $pages = 2; # for testing
  say "Entries: $entries\tPages:  $pages";
  
  $twig->purge();
  
  if ($pages) {
    for (my $i=1; $i <= $pages; $i++) {
#      say $i;
      my $respRef = &gist( $query, $i );
      my $content = $$respRef;
      &handler( $content );
      
#      say $response, "\n\n";
 #     &process_record( $response );
    }
  }
}



sub handler {

#   my $resRef = shift;
#   my $response = $$resRef;

  my $response = shift;
  my $twig = new XML::Twig( twig_handlers => { 'Record' => \&process_record });
  $twig->parse( $response );

}

sub process_record {
  my ($twig, $entry) = @_;

  my $person = $entry->first_descendant('Person') if ( $entry->first_descendant('Person') );
  my $surname = $person->first_child('FamilyName')->text if ( $person->first_child('FamilyName') );
  my $firstname = $person->first_child('GivenName')->text if ($person->first_child('GivenName') );
  
  my $pi = ($surname) ? ("$firstname $surname") : "no pi";
  
  # Grant
  my $grant = $entry->first_descendant('Grant');
  my $funder = $grant->first_child('Funder')->text;
  my $id = $grant->first_child('Id')->text;
  my $title = $grant->first_child('Title')->text;
  my $abst = $grant->first_child('Abstract')->text if ($grant->first_child('Abstract'));
  
  my $abstract = ($abst) ? $abst : "no abstract";
  
  my $type = $grant->first_child('Type')->text if ($grant->first_child('Type'));
  my $start = $grant->first_child('StartDate')->text if ($grant->first_child('StartDate'));
  my $end = $grant->first_child('EndDate')->text if ($grant->first_child('EndDate'));
  my $amount = $grant->first_child('Amount')->text if ($grant->first_child('Amount'));
  
  my $grantType = ($type) ? $type : "not defined";
  my $duration = ($start) ? "$start-$end" : "not defined";
  my $value = ($amount) ? $amount : "not defined";
  
  say $pi, "\t", $funder, "\t", $id, "\t", $title, 
    "\t", $grantType, "\t", $duration, "\t", $value,
    "\t", $abstract;
    
  $twig->purge();
}

