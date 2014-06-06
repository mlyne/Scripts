#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common qw/POST/;
#use URI::Escape;
use XML::Twig;
use Data::Dumper;

my $usage = "Usage:epo_patent.pl query_file out_file
    
Fields: ti	title in English
ab	abstract in English
ta	title or abstract
in	inventor name
pa	applicant name
ia	inventor or an applicant
txt	publication title or abstract, or inventor/applicant name
pn	publication number (any)
spn	publication number (epodoc form)
ap	application number (any)
sap	application number (epodoc form) 
pr	priority number
spr yes the priority number in epodoc format
num	publication, application or priority nm (any)
pd	publication date
ct	cited document num
ipc, ic no any IPC1-8 class

Examples:
ti all \"green, energy\"
ti=green prox/unit=world ti=energy
pd=\"20051212 20051214\"
ia any \"John, Smith\"
pn=EP and pr=GB
ta=green prox/distance<=3 ta=energy
ta=green prox/distance<=2/ordered=true ta=energy
(ta=green prox/distance<=3 ta=energy) or (ta=renewable prox/distance<=3 ta=energy)
pa all \"central, intelligence, agency\" and US
pa all \"central, intelligence, agency\" and US and pd>2000
pd < 18000101
ta=synchroni#ed
EP and 2009 and Smith
cpc=/low A01B

AND, OR, NOT
\*	zero or more
\?	zero or one
\#	exactly one
    
n";

unless ( $ARGV[0] ) { die $usage };

# specify and open query file (format: )
my $query_file = $ARGV[0];
my $outFile = $ARGV[1];

open(QFILE, "< $query_file") || die "cannot open $query_file: $!\n";
open(OUT_FILE, "> $outFile") || die "cannot open $outFile: $!\n";

while (<QFILE>)
{
  chomp;
  my ($searchStr, $inVal) = split(/\t/, $_);
  my $query = "$searchStr";
  
  my $range = defined $inVal ? ($inVal) : ("1");
  
  print OUT_FILE "PATENT SEARCH: ", $query, "\n";

  my $respRef = ops_post($query, $range);
  my $out = $$respRef;
  
  my $valid = "true" if ($out =~ m/search-result/);

# Then use pattern match to retrieve the line with count info
# feed into $entry

  my ($hitCount) = defined $valid ? ($out =~ m/biblio\-search total\-result\-count\=\"(\d+)\"/) : undef;
  print OUT_FILE "Patent Count: ", $hitCount, "\n";
  
  return unless $hitCount;
    
    ### apply thresholds to patents returned ###
    
#    if ($hitCount >250) {
  if ($hitCount >1000) {
    print OUT_FILE "Patent count $hitCount out of scope (scope: count < 1000)\n";
    next;
    #return;
  }
  
    if ($hitCount <= 100) {
    $range = "1-$hitCount";
    my $respRef = ops_post($query, $range);
    handler($respRef);
#    print  "range: $range\n";
  } else {
    
    my $start = 1;
    my $end = 100;
    $range = "$start\-$end";
#    print "RANGE: $range\n";
    
    my $respRef = ops_post($query, $range);
    handler($respRef);
    
#    print "range: ", $start,  "-", $end, "\n";

    while (($end + 100) < $hitCount) {
      $start = ($end +1);
      $end = ($start + 99);
      $range = "$start\-$end";
      
      $respRef = ops_post($query, $range);
      handler($respRef);
      
#      print "range: ", $start,  "-", $end, "\n";
    }
    
    $start = ($end +1);
    $end = $hitCount;
    $range = "$start\-$end";
    
    $respRef = ops_post($query, $range);
    handler($respRef);
    
#    print "range: ", $start, "-", $end, "\n";
    
    }
}

close(QFILE);
close(OUT_FILE);

sub ops_post {

  my $ua = LWP::UserAgent->new();

  my $query = shift || die "no query $!\n";
  my $range = shift;
  my $url;

  if ($range =~ /-/) {
#    print "RANGE\n";
    $url = 'http://ops.epo.org/3.0/rest-services/published-data/search/biblio'; 
  } else {
    $url = 'http://ops.epo.org/3.0/rest-services/published-data/search';
  }
  
  my $request = POST ( $url, 
			Range => $range,
			Content => [ 'q' => "$query" ]
 );

  my $response = $ua->request($request);
  die 'http status: ' . $response->code . ' ' . $response->message unless ($response->is_success); 

  my $out = $response->content();
#  print $out, "\n\n";
  
  print OUT_FILE "\nProcessing range... $range\n";
  
  sleep(5);
  return \$out;
  
}

sub handler {

  my $resRef = shift;
  my $response = $$resRef;
  my $twig = new XML::Twig( twig_handlers => { 'exchange-document' => \&process_patRes });
  $twig->parse( $response );

}

sub process_patRes {
  my ($twig, $entry) = @_;
  
#  print Dumper ($twig);
  
  my $fam = $entry->att( 'family-id');
  print OUT_FILE "Family: ", $fam, "\n";
  
  my @docIds = $entry->descendants('publication-reference');
  
  foreach my $idRef (@docIds) {
    my $epoIdRef = $idRef->first_descendant('document-id[@document-id-type="epodoc"]') if $idRef;
    my $docNo = $epoIdRef->first_descendant('doc-number')->text  if $epoIdRef;
    my $docDate = $epoIdRef->first_descendant('date')->text  if $epoIdRef;
    print OUT_FILE "Document: ", $docNo, "\t:\t$docDate\n" if ($docNo && $docDate);
  }

  my @ipcList = $entry->descendants('/classification-ipc\b/');

 foreach my $ipc (@ipcList) {
  print OUT_FILE "IPC: ", $ipc->first_descendant('text')->text, "\n" if $ipc;
  }
  
  my $title = $entry->first_descendant('invention-title')->text;
  print OUT_FILE "Title: ", $title, "\n";
  
  my @applicants = $entry->descendants('applicants');
  
  foreach my $applicants (@applicants) {
    my $applicant = $applicants->first_descendant('applicant[@data-format="epodoc"]') if $applicants;
    my $app = $applicant->first_descendant('applicant-name')  if $applicant;
    print OUT_FILE "Applicant: ", $app->first_descendant('name')->text, "\n" if $app;
  }
  
#  my @inventors = $entry->descendants('inventors');
  my @inventors = $entry->descendants('inventor[@data-format="epodoc"]');
  
  foreach my $inventors (@inventors) {
#    print $inventors, "\n";
#    my $invenType = $inventors->first_descendant('inventor[@data-format="epodoc"]');
#    my $invenTag = $invenType->first_descendant('inventor-name');
    my $invenTag = $inventors->first_descendant('inventor-name') if $inventors;
    print OUT_FILE "Inventor: ", $invenTag->first_descendant('name')->text, "\n" if $invenTag;
  }
  print OUT_FILE "--- END Patent ---\n\n";
  $twig->purge();
}