#!/usr/bin/perl

# Practical 3, Exercise 2
# Download DocSums for all structures with resolutions less than 2 Angstroms

# ESearch - ESummary

use strict;
use NCBI_PowerScripting;

my (%sparams, %sresults, %mparams);

#ESearch
$sparams{'db'} = 'structure';
$sparams{'term'} = '0:2[resolution]';
$sparams{'usehistory'} = 'y';

%sresults = esearch(%sparams);

#ESummary
$mparams{'db'} = $sparams{'db'};
$mparams{'query_key'} = $sresults{'query_key'};
$mparams{'WebEnv'} = $sresults{'WebEnv'};
$mparams{'outfile'} = 'ex3-2.sum';

esummary(%mparams);
