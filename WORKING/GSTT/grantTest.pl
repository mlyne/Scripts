#!/usr/bin/perl

use strict;
use warnings;
require LWP::UserAgent;
use XML::Twig;

use feature ':5.12';

my $base = "http://plus.europepmc.org/GristAPI/rest/get/query=";
my $query = "pi:peakman";
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
  
  my $surname = $entry->first_descendant('Person')->first_child('FamilyName')->text;
  my $firstname = $entry->first_descendant('Person')->first_child('GivenName')->text;
  
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
  
  say "PI name: $firstname $surname";
  say $funder, " : ", $id, " : ", $title;
  say $grantType, " : ", $duration, " : ", $value;
  say $abstract;
  say "";
}

