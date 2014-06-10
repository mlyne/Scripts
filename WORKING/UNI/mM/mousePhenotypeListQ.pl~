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

# The following import statement sets metabolicMine as your default
# You must also supply your login details here to access this query
use Webservice::InterMine 0.9904 'http://www.metabolicmine.org/beta', 'g1f3ucDaH6x05eD7qd8dH1BdbOR';

my $query = new_query(class => 'Gene');

# The view specifies the output columns
$query->add_view(qw/
    symbol
    name
    homologues.homologue.organism.shortName
    homologues.homologue.symbol
    homologues.homologue.name
    homologues.homologue.alleles.symbol
    homologues.homologue.alleles.name
    homologues.homologue.alleles.primaryIdentifier
    homologues.homologue.alleles.genotypes.name
    homologues.homologue.alleles.genotypes.zygosity
    homologues.homologue.alleles.genotypes.geneticBackground
    homologues.homologue.alleles.genotypes.phenotypeTerms.identifier
    homologues.homologue.alleles.genotypes.phenotypeTerms.name
    homologues.homologue.alleles.genotypes.phenotypeTerms.description
    homologues.homologue.alleles.genotypes.phenotypeTerms.ontology.name
/);

# edit the line below to change the sort order:
# $query->add_sort_order('symbol', 'ASC');

$query->add_constraint(
    path  => 'Gene.homologues.homologue.organism.shortName',
    op    => '=',
    value => 'M. musculus',
    code  => 'B',
);
$query->add_constraint(
    path  => 'Gene',
    op    => 'IN',
    value => 'Speliotes_Diabesity_olap',
    code  => 'A',
);

# Edit the code below to specify your own custom logic:
# $query->set_logic('B and A');

# Use an iterator to avoid having all rows in memory at once.
my $it = $query->iterator();
while (my $row = <$it>) {
    print $row->{'symbol'}, $row->{'name'}, $row->{'homologues.homologue.organism.shortName'},
        $row->{'homologues.homologue.symbol'}, $row->{'homologues.homologue.name'},
        $row->{'homologues.homologue.alleles.symbol'}, $row->{'homologues.homologue.alleles.name'},
        $row->{'homologues.homologue.alleles.primaryIdentifier'},
        $row->{'homologues.homologue.alleles.genotypes.name'},
        $row->{'homologues.homologue.alleles.genotypes.zygosity'},
        $row->{'homologues.homologue.alleles.genotypes.geneticBackground'},
        $row->{'homologues.homologue.alleles.genotypes.phenotypeTerms.identifier'},
        $row->{'homologues.homologue.alleles.genotypes.phenotypeTerms.name'},
        $row->{'homologues.homologue.alleles.genotypes.phenotypeTerms.description'},
        $row->{'homologues.homologue.alleles.genotypes.phenotypeTerms.ontology.name'}, "\n";
}

