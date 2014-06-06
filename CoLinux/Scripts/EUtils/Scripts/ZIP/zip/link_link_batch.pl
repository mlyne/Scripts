#!/usr/bin/perl

# ELink (batch) - ELink (batch)

use strict;
use NCBI_PowerScripting;

my (%params1, %params2, %links1, %links2);
my @uids;

#ELink 1

$params1{'dbfrom'} = 'nucleotide';
$params1{'db'} = 'protein';
$params1{'id'} = '56181373,56181375,56181371,21614549';

%links1 = elink_batch(%params1);

#ELink 2

$params2{'dbfrom'} = $params1{'db'};
$params2{'db'} = 'cdd';
$params2{'query_key'} = $links1{'query_key'};
$params2{'WebEnv'} = $links1{'WebEnv'};

%links2 = elink_batch(%params2);

#Recover UIDs

$links2{'db'} = $params2{'db'};

@uids = get_uids(%links2);

foreach (@uids) { print "$_ ";}
print "\n";
