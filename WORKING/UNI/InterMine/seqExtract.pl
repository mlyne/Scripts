#!/usr/bin/perl

######################################################################
# This is an automatically generated script to run your query.
# To use it you will require the InterMine Perl client libraries.
# These can be installed from CPAN, using your preferred client, eg:
#
#    sudo cpan Webservice::InterMine
#
# For help using these modules, please see these resources:
#
#  * https://metacpan.org/pod/Webservice::InterMine
#       - API reference
#  * https://metacpan.org/pod/Webservice::InterMine::Cookbook
#       - A How-To manual
#  * http://www.intermine.org/wiki/PerlWebServiceAPI
#       - General Usage
#  * http://www.intermine.org/wiki/WebService
#       - Reference documentation for the underlying REST API
#
######################################################################

use strict;
use warnings;
#use LWP::Simple;
use URI::Escape;
use Data::Dumper;

require LWP::UserAgent;

# Set the output field separator as tab
$, = "\t";
# Print unicode to standard out
binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

# This code makes use of the Webservice::InterMine library.
# The following import statement sets SynBioMine Test as your default
#use Webservice::InterMine 1.0404 'http://www.flymine.org/synbiomine';

my $base = "http://www.flymine.org/synbiomine/service/sequence?";
my $chrom = "NC_000964.3";
my $start = "1234";
my $end = "1256";
my $coord = "start=$start\&end=$end";

my $query = '&query=<query model="genomic" view="Chromosome.sequence.residues"><constraint ' .
'path="Chromosome" op="LOOKUP" value=' .
"\"$chrom\"" .
'/></query>';

# "http://www.flymine.org/synbiomine/service/sequence?start=1234&end=1256&query=<query model="genomic" view="Chromosome.sequence.residues"><constraint path="Chromosome" op="LOOKUP" value="NC_000964.3"/></query>"

my $safe = uri_escape("$coord$query"); # not needed for request

my $url = "$base$coord$query";

#print $bare, "\n",
#$url, "\n";

my $agent    = LWP::UserAgent->new;
my $request  = HTTP::Request->new(GET => $url);
my $response = $agent->request($request);
$response->is_success or print "$chrom\tError: " . 
$response->code . " " . $response->message, "\n";
print $response->content, "\n";

#print Dumper($response);


# my $query = new_query(class => 'Chromosome');
# 
# # The view specifies the output columns
# $query->add_view(qw/
#     primaryIdentifier
#     sequence.residues
# /);
# 
# # edit the line below to change the sort order:
# # $query->add_sort_order('primaryIdentifier', 'ASC');
# 
# $query->add_constraint(
#     path  => 'Chromosome.primaryIdentifier',
#     op    => '=',
#     value => 'NC_000964.3',
#     code  => 'A',
# );
# 
# # Use an iterator to avoid having all rows in memory at once.
# my $it = $query->iterator();
# while (my $row = <$it>) {
#     print $row->{'primaryIdentifier'}, $row->{'sequence.residues'}, "\n";
# }
# 
