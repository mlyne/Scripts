#!/usr/bin/perl

#Problem 4-1b

use strict;
use NCBI_PowerScripting;

my (%params, %results, %sparams);
my (%lparams, %links);
my @uids;

%params = read_params();

%results = esearch(%params);

$lparams{'WebEnv'} = $results{'WebEnv'};
$lparams{'query_key'} = $results{'query_key'};
$lparams{'dbfrom'} = $params{'db'};
$lparams{'db'} = 'pubmed';

%links = elink_batch(%lparams);

$links{'db'} = $lparams{'db'};

@uids = get_uids(%links);

foreach (@uids) {
   print "$_\n";
}
