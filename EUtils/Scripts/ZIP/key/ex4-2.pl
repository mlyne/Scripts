#!/usr/bin/perl

# Practical 4, Exercise 2
# Download protein GIs linked to each mouse gene on chromosome 11 that has SNPs

# ESearch - ELink (by id)

use strict;
use NCBI_PowerScripting;

my (%sparams, %sresults, %lparams, %links, %mparams);

#ESearch
$sparams{'db'} = 'gene';
$sparams{'term'} = 'mouse[orgn]+AND+11[chromosome]+AND+%22gene+snp%22[filter]';
$sparams{'usehistory'} = 'y';

%sresults = esearch(%sparams);

#ELink
$lparams{'dbfrom'} = $sparams{'db'};
$lparams{'db'} = 'protein';
$lparams{'query_key'} = $sresults{'query_key'};
$lparams{'WebEnv'} = $sresults{'WebEnv'};
$lparams{'outfile'} = 'ex4-2';

%links = elink_by_id(%lparams);

