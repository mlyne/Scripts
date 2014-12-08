#!/usr/bin/env perl
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Date;

use feature ':5.12';

my $usage = "fetchUniprotProteomes.pl [y]

if 2nd cmd line option 'y' is given, proteome is set to 'reference proteome'
Otherwise, 'complete proteomes' are downloaded

";

# Taxonomy identifier of top node for query, e.g. 2 for Bacteria, 2157 for Archea, etc.
# (see http://www.uniprot.org/taxonomy)
my $ref_check = $ARGV[0];

$ARGV[0] or die $usage;

my $reference = $ref_check ? 'reviewed:yes' : 'reviewed:no';
#my $keyword = $ref_check ? 'keyword:1185' : 'keyword:181';
my $db = $ref_check ? "_swiss" : "_trembl";

my @taxon_list = qw|224308 83333 511145|;

my $contact = 'mike@intermine.org'; # Please set your email address here to help us debug in case of problems.
my $agent = LWP::UserAgent->new(agent => "libwww-perl $contact");

# For each taxon
for my $taxon (@taxon_list) {
  say "Taxon: ", $taxon;

  my $success = &query_uniprot($db, $taxon, $reference);

  unless ($success) {
    $reference = 'reviewed:no';
    $db = "_trembl";
    &query_uniprot($db, $taxon, $reference);
  }

}

sub query_uniprot {

  my ($db, $taxon, $reference) = @_;

# Alternative formats: html | tab | xls | fasta | gff | txt | xml | rdf | list | rss
  my $file = $taxon . $db . '.xml';
  my $query_taxon = "http://www.uniprot.org/uniprot/?query=organism:$taxon+$reference&format=xml&include=yes";

  my $response_taxon = $agent->mirror($query_taxon, $file);

  if ($response_taxon->is_success) {
    say "Success for Taxon: $taxon";

    my $results = $response_taxon->header('X-Total-Results');
    unless ($results) {
      if ($db =~ /swiss/) {
	say "No SwissProt results for $taxon: trying TrEMBL";
	unlink $file;
	return;
      }
      else {
	say "No TrEMBL results for $taxon";
	unlink $file;
	return;
      }
    }

    my $release = $response_taxon->header('X-UniProt-Release');
    my $date = sprintf("%4d-%02d-%02d", HTTP::Date::parse_date($response_taxon->header('Last-Modified')));
    say "File $file: downloaded $results entries of UniProt release $release ($date)";
    return 1;
  }
  elsif ($response_taxon->code == HTTP::Status::RC_NOT_MODIFIED) {
    say "File $file: up-to-date";
  }
  else {
    warn 'Failed, got ' . $response_taxon->status_line .
      ' for ' . $response_taxon->request->uri . "\n";
  }
  return;
}
