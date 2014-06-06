#!/usr/bin/perl

# ELink (batch) - ESearch

use strict;
use NCBI_PowerScripting;

my (%sparams, %sresults, %lparams, %links);
my @uids;

#ELink

$lparams{'dbfrom'} = 'nucleotide';
$lparams{'db'} = 'protein';
$lparams{'id'} = '56181373,56181375,56181371,21614549';

%links = elink_batch(%lparams);

#ESearch

$sparams{'db'} = $lparams{'db'};
$sparams{'term'} = "%23$links{'query_key'}+AND+srcdb+refseq[prop]";
$sparams{'WebEnv'} = $links{'WebEnv'};
$sparams{'usehistory'} = 'y';

%sresults = esearch(%sparams);

#Recover UIDs

$sresults{'db'} = $sparams{'db'};

@uids = get_uids(%sresults);

foreach (@uids) { print "$_ ";}
print "\n";
