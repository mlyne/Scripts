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

my $query = new_query(class => 'Gene');

# The view specifies the output columns
$query->add_view(qw/
    primaryIdentifier
    symbol
    promoters.primaryIdentifier
    promoters.sigmaBindingFactors.primaryIdentifier.primaryIdentifier
    promoters.transcriptionFactor.primaryIdentifier.symbol
    promoters.transcriptionFactor.primaryIdentifier.primaryIdentifier
    promoters.sigmaBindingFactors.primaryIdentifier.symbol
    promoters.transcriptionFactor.regulation
    promoters.sequence.residues
/);

# edit the line below to change the sort order:
# $query->add_sort_order('primaryIdentifier', 'ASC');

# Outer Joins
# (Show attributes of these relations if they exist, but do not require them to exist.)
$query->add_outer_join('promoters.transcriptionFactor');
$query->add_outer_join('promoters.sigmaBindingFactors');
$query->add_outer_join('promoters.sequence');


# Use an iterator to avoid having all rows in memory at once.
my $it = $query->iterator();
while (my $row = <$it>) {
    print $row->{'primaryIdentifier'}, $row->{'symbol'}, $row->{'promoters.primaryIdentifier'},
        $row->{'promoters.sigmaBindingFactors.primaryIdentifier.primaryIdentifier'},
        $row->{'promoters.transcriptionFactor.primaryIdentifier.symbol'},
        $row->{'promoters.transcriptionFactor.primaryIdentifier.primaryIdentifier'},
        $row->{'promoters.sigmaBindingFactors.primaryIdentifier.symbol'},
        $row->{'promoters.transcriptionFactor.regulation'}, $row->{'promoters.sequence.residues'}, "\n";
}