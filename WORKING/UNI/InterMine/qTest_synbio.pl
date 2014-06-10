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
#  * http://search.cpan.org/perldoc?Webservice::InterMine
#       - API reference
#  * http://search.cpan.org/perldoc?Webservice::InterMine::Cookbook
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

# The following import statement sets SynBioMine as your default
use Webservice::InterMine 0.9904 'http://www.flymine.org/synbiomine';

# Description: Show the proteins for a particular gene.

my $template = Webservice::InterMine->template('Gene_Protein')
    or die 'Could not find a template called Gene_Protein';

# Use an iterator to avoid having all rows in memory at once.
my $it = $template->results_iterator_with(
    # A:  Gene
    opA    => 'LOOKUP',
    valueA => 'ArcA',
    extra_valueA => 'E. coli str. K-12 substr. MG1655',
);

while (my $row = <$it>) {
    print $row->{'primaryIdentifier'}, $row->{'symbol'}, $row->{'proteins.primaryIdentifier'},
        $row->{'proteins.primaryAccession'}, "\n";
}
