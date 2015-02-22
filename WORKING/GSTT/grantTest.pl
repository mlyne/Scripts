#!/usr/bin/perl

use strict;
use warnings;
require LWP::UserAgent;
use XML::Twig;

use feature ':5.12';

my $base = "http://plus.europepmc.org/GristAPI/rest/get/query=";
my $query = "aff:\"king's college london\"";
#my $query = "aff:london & pi:peakman";
my $format = "&resultType=core";
my $url = $base . $query . $format;

my $agent = LWP::UserAgent->new;

my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);

$response->is_success or say "Error: " . 
$response->code . " " . $response->message;

my $content = $response->content;
#say $content;

&handler($content);

exit(1);

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
}

