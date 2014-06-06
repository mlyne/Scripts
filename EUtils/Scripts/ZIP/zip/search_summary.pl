#!/usr/bin/perl

# ESearch - ESummary

use strict;
use NCBI_PowerScripting;

my (%sparams, %sresults, %mparams);

#ESearch
$sparams{'db'} = 'protein';
$sparams{'term'} = 'mouse[orgn]+AND+transcarbamylase[title]';
$sparams{'usehistory'} = 'y';

%sresults = esearch(%sparams);

#ESummary
$mparams{'db'} = $sparams{'db'};
$mparams{'query_key'} = $sresults{'query_key'};
$mparams{'WebEnv'} = $sresults{'WebEnv'};
$mparams{'outfile'} = 'docsums.out';

esummary(%mparams);
