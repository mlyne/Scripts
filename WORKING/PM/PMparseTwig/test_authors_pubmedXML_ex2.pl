#!/usr/bin/perl
use strict;
use warnings;

# use module
use LWP::Simple;
use XML::Simple;
use Data::Dumper;

#open (FH, ">:utf8","xmlparsed1.txt");

## Uncomment to access PM through LWP
#my $db1 = "pubmed";
#my $q = 16404398;

my $xml = new XML::Simple;

#my $urlxml = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=$db1&id=$q&retmode=xml&rettype=abstract";
#my $dataxml = get($urlxml);

#my $data = $xml->XMLin("$dataxml", ForceArray => [qw( MeshHeading AuthorList )]);
#print FH Dumper($data);
#print FH "Authors: ".join '$$', map $_->{LastName},@{$data->{PubmedArticle}->{MedlineCitation}->{Article}->{AuthorList}->[0]->{Author}};
	
## Uncomment to read from LWP stream
# my $data = $xml->XMLin("$dataxml", ForceArray => [qw( MeshHeading Author )]);

## Read from XML file
my $data = $xml->XMLin("pubmed_result.xml", ForceArray => [qw( MeshHeading Author )]);

print "ENTRY\n";

my $author_list = $data->{PubmedArticle}{MedlineCitation}{Article}{AuthorList}{Author};
foreach my $author ( @$author_list ) {
    print "Author: $author->{LastName}, $author->{ForeName}\n";
}

print $data->{PubmedArticle}->{MedlineCitation}->{Article}->{Journal}->{ISOAbbreviation}, " ";
print $data->{PubmedArticle}->{MedlineCitation}->{Article}->{Journal}->{JournalIssue}->{PubDate}->{Year}, ";", ;
print $data->{PubmedArticle}->{MedlineCitation}->{Article}->{Journal}->{JournalIssue}->{Volume}, ":";
print $data->{PubmedArticle}->{MedlineCitation}->{Article}->{Pagination}->{MedlinePgn}, "." ;
print "\n";

# Author: Butte, Atul J
# Author: Kohane, Isaac S
