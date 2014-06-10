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

# Set the output field separator as tab
$, = "\t";
# Print unicode to standard out
binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

# This code makes use of the Webservice::InterMine library.
# The following import statement sets SynBioMine as your default
# You must also supply your login details here to access this query
use Webservice::InterMine 0.9904 'http://www.flymine.org/synbiomine', 'N1G4u22eA7f8g667V3x3';

# Description: For a given gene (or list of genes) returns the location.

my $template = Webservice::InterMine->template('GeneCoord')
    or die 'Could not find a template called GeneCoord';

# Use an iterator to avoid having all rows in memory at once.
my $it = $template->results_iterator_with(
    # A:  Gene
    opA    => 'IN',
    valueA => 'BcereusATCC14579orthologues_Bsub168_allGenes',
);

while (my $row = <$it>) {
    print $row->{'primaryIdentifier'}, $row->{'chromosome.primaryIdentifier'},
        $row->{'chromosomeLocation.start'}, $row->{'chromosomeLocation.end'},
        $row->{'chromosomeLocation.strand'}, $row->{'organism.shortName'}, "\n";
}