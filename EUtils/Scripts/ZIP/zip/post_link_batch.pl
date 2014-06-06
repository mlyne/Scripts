#!/usr/bin/perl

# EPost - ELink (batch)
# UIDs are recovered with get_uids

use strict;
use NCBI_PowerScripting;

my (%pparams, %posted, %lparams, %links);
my @uids;

#EPost
$pparams{'db'} = 'protein';
$pparams{'id'} = 'proteins.gi';

%posted = epost_file(%pparams);

#ELink
$lparams{'dbfrom'} = $pparams{'db'};
$lparams{'db'} = 'nucleotide';
$lparams{'query_key'} = $posted{'query_key'};
$lparams{'WebEnv'} = $posted{'WebEnv'};

%links = elink_batch(%lparams);

#Recover UIDs

$links{'db'} = $lparams{'db'};

@uids = get_uids(%links);

foreach (@uids) { print "$_ ";}
print "\n";
