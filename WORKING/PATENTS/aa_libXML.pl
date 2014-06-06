#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common qw/POST/;
use XML::LibXML;
use feature qw( say );
#use URI::Escape;
##use XML::Twig;
##use Data::Dumper;

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

unless ( $ARGV[0] ) { die $usage }

# specify and open query file (format: )
my $query_file = $ARGV[0];
open(QFILE, "< $query_file") || die "cannot open $query_file: $!\n";

while (<QFILE>)
{
  chomp;
#  my ($query, $range) = split(/\t/, $_);
  my ($searchStr, $range) = split(/\t/, $_);
  my $query = "$searchStr";

# Create a user agent
my $ua = LWP::UserAgent->new();
 
 # URL for service (endpoint) 
 my $url = 'http://ops.epo.org/3.0/rest-services/published-data/search/biblio';
 
 my $request = POST ( $url, 
		      Range => $range,
		      Content => [ 'q' => "$query" ]
 );
 
 my $response = $ua->request($request);
 die 'http status: ' . $response->code . ' ' . $response->message unless ($response->is_success); 
 
#    $countHead =~ m|<Count>(\d+)</Count>.*<QueryKey>(\d+)</QueryKey>.*<WebEnv>(\S+)</WebEnv>|s;
  my $out = $response->content();
  my $valid = "true" if ($out =~ m/search-result/);

# Then use grep to retrieve the line with reference info
# feed into $entry

  my ($hitCount) = defined $valid ? ($out =~ m/biblio\-search total\-result\-count\=\"(\d+)\"/) : ("12321");
  print "Count: ", $hitCount, "\n";
  
  my $parser = XML::LibXML->new();
  my $doc = $parser->parse_string($out);
  my $root = $doc->documentElement();

#  for my $node ($root->findnodes('exchange-documents')) {
    my $elname = $root-> getName();
    print "Root element is a $elname and it contains ...\n";
    
#    for my $node ($root->findnodes('ops:search-result/exchange-documents/exchange-document/bibliographic-data/parties/applicants/applicant/applicant-name/name' ) ) {
    for my $node ($root->findnodes('//applicant-name/name' ) ) {
#    my $nodel = $node->getName();
#    print "node is a $nodel and it contains ...\n";
    say join ':', $node->nodeValue(); #  // '', $node->textContent();
    }
    
#   say join ':', $node->getAttribute('family-id') // '', $node->textContent();
#   }
 
#  print Dumper( $response->content() );
#  print $out;
 
#  my $twig = new XML::Twig( twig_handlers => { 'exchange-document' => \&process_patRes });
#  $twig->parse( $out );
 
 # Output the entry
# print $response->content();
  
  # To comply with fair use policy
  sleep(5);
# select(undef, undef, undef, 5); # EPO requires that we have no more than 10 requests / minute so delay 5 secs

}

close(QFILE);


sub process_patRes {
  my ($twig, $entry) = @_;
  
  my $fam = $entry->first_descendant('doc-number')->text;
  print "Processing doc number $fam...\n";

}