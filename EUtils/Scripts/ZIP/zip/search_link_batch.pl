#!/usr/bin/perl

# ESearch - ELink (batch)
# UIDs are recovered with get_uids

use strict;
use NCBI_PowerScripting;

my (%sparams, %sresults, %lparams, %links);
my @uids;

#ESearch
$sparams{'db'} = 'protein';
$sparams{'term'} = 'mouse[orgn]+AND+transcarbamylase[title]';
$sparams{'usehistory'} = 'y';

%sresults = esearch(%sparams);

#ELink
$lparams{'dbfrom'} = $sparams{'db'};
$lparams{'db'} = 'nucleotide';
$lparams{'query_key'} = $sresults{'query_key'};
$lparams{'WebEnv'} = $sresults{'WebEnv'};

%links = elink_batch(%lparams);

#Recover UIDs

$links{'db'} = $lparams{'db'};

@uids = get_uids(%links);

foreach (@uids) { print "$_ ";}
print "\n";
