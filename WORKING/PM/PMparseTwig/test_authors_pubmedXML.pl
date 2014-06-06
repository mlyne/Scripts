#!/usr/bin/perl
use strict;
use warnings;

# use module
use XML::Simple;
use Data::Dumper;

# create object
$xml = new XML::Simple (KeyAttr=>[]);

## see stuff on forcearray and keyAttr: http://www.perlmonks.org/?node_id=218480

#read XML file
# $data = $xml->XMLin("data.xml");
my $data = $xml->XMLin("$data.xml", ForceArray => [qw( MeshHeading Author )]);

#dereference hash ref

#print Dumper($data);
print $data->{PMID}, "\n";
print $data->{Article}->{ArticleTitle}, "\n";

#foreach $e (@{$data->{Article}->{AuthorList}->{Author}})
#{
#	$authors.= $e->{LastName}." ".$e->{Initials}.', ';
#}

my $author_list = $data->{PubmedArticle}{MedlineCitation}{Article}{AuthorList}{Author};
foreach my $author ( @$author_list ) {
    print "Author: $author->{LastName}, $author->{ForeName}\n";
}

print $data->{Article}->{Journal}->{ISOAbbreviation}, " ";
print $data->{Article}->{Journal}->{JournalIssue}->{PubDate}->{Year}, ";", ;
print $data->{Article}->{Journal}->{JournalIssue}->{Volume}, ":";
print $data->{Article}->{Pagination}->{MedlinePgn}, "." ;
print "\n";

######################################

