#!/usr/bin/perl

# EPost - ESearch

use strict;
use NCBI_PowerScripting;

my (%pparams, %posted, %sparams, %sresults);
my @uids;

#EPost
$pparams{'db'} = 'protein';
$pparams{'id'} = 'proteins.gi';

%posted = epost_file(%pparams);

#ESearch
$sparams{'db'} = $pparams{'db'};
$sparams{'term'} = "%23$posted{'query_key'}+AND+srcdb+swiss+prot[prop]";
$sparams{'WebEnv'} = $posted{'WebEnv'};
$sparams{'usehistory'} = 'y';

%sresults = esearch(%sparams);

#Retreive UIDs

$sresults{'db'} = $sparams{'db'};

@uids = get_uids(%sresults);

foreach (@uids) { print "$_ "; }
print "\n";
