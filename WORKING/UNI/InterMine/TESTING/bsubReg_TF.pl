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

my $query = new_query(class => 'Promoter');

# The view specifies the output columns
$query->add_view(qw/
    primaryIdentifier
    transcriptionFactor.primaryIdentifier.primaryIdentifier
    transcriptionFactor.primaryIdentifier.symbol
    gene.primaryIdentifier
    gene.symbol
    transcriptionFactor.regulation
    sequence.residues
    evidence.publications.pubMedId
/);

# edit the line below to change the sort order:
# $query->add_sort_order('primaryIdentifier', 'ASC');

# Outer Joins
# (Show attributes of these relations if they exist, but do not require them to exist.)
$query->add_outer_join('sequence');
$query->add_outer_join('evidence');


# Use an iterator to avoid having all rows in memory at once.
my $it = $query->iterator();
while (my $row = <$it>) {
#    print $row->{'primaryIdentifier'},
        print $row->{'transcriptionFactor.primaryIdentifier.primaryIdentifier'},
        $row->{'transcriptionFactor.primaryIdentifier.symbol'}, $row->{'gene.primaryIdentifier'},
        $row->{'gene.symbol'}, $row->{'transcriptionFactor.regulation'}, $row->{'evidence.publications.pubMedId'},
	$row->{'sequence.residues'}, "\n";
}