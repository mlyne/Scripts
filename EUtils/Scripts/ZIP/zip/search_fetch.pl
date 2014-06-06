#!/usr/bin/perl

# ESearch - EFetch

use strict;
use NCBI_PowerScripting;

my (%sparams, %sresults, %fparams);

#ESearch
$sparams{'db'} = 'protein';
$sparams{'term'} = 'mouse[orgn]+AND+transcarbamylase[title]';
$sparams{'usehistory'} = 'y';

%sresults = esearch(%sparams);

#EFetch
$fparams{'db'} = $sparams{'db'};
$fparams{'query_key'} = $sresults{'query_key'};
$fparams{'WebEnv'} = $sresults{'WebEnv'};
$fparams{'rettype'} = 'fasta';
$fparams{'retmode'} = 'text';
$fparams{'outfile'} = 'fasta.out';

efetch_batch(%fparams);
