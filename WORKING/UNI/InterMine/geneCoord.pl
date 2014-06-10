#!/usr/bin/perl

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
use Webservice::InterMine 1.0405 'http://www.flymine.org/synbiomine';

# Description: For a given gene (or List of Genes) returns the location
# co-ordinates.
my $identifier = shift;
my $org_short = "B. subtilis subsp. subtilis str. 168";

my $query = new_query(class => 'Gene');

# The view specifies the output columns
$query->add_view(qw/
    primaryIdentifier
    symbol
    chromosome.primaryIdentifier
    chromosomeLocation.start
    chromosomeLocation.end
    chromosomeLocation.strand
    organism.shortName
/);

# edit the line below to change the sort order:
# $query->add_sort_order('primaryIdentifier', 'ASC');

$query->add_constraint(
    path        => 'Gene',
    op          => 'LOOKUP',
    value       => "$identifier",
    extra_value => "$org_short",
    code        => 'A',
);

# Use an iterator to avoid having all rows in memory at once.
my @gene_lookups;
my $it = $query->iterator();
while (my $row = <$it>) {
    push (@gene_lookups, [$row->{'primaryIdentifier'}, 
			  $row->{'symbol'}, 
			  $row->{'chromosome.primaryIdentifier'},
			  $row->{'chromosomeLocation.start'}, 
			  $row->{'chromosomeLocation.end'},
			  $row->{'chromosomeLocation.strand'}, 
			  $row->{'organism.shortName'} ,])
}

print scalar(@gene_lookups), "\n";
for my $result (@gene_lookups) {
  print join("\t", @{ $result }), "\n";
}
