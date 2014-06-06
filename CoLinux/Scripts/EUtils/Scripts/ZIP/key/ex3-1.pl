#!/usr/bin/perl

# Practical 3, Exercise 1
# Download all rat Reference Sequences in FASTA format

# ESearch - EFetch

use strict;
use NCBI_PowerScripting;

my (%sparams, %sresults, %fparams);

#ESearch
$sparams{'db'} = 'protein';
$sparams{'term'} = 'rat[orgn]+AND+srcdb+refseq[prop]';
$sparams{'usehistory'} = 'y';

%sresults = esearch(%sparams);

#EFetch
$fparams{'db'} = $sparams{'db'};
$fparams{'query_key'} = $sresults{'query_key'};
$fparams{'WebEnv'} = $sresults{'WebEnv'};
$fparams{'rettype'} = 'fasta';
$fparams{'retmode'} = 'text';
$fparams{'outfile'} = 'ex3-1.faa';

efetch_batch(%fparams);
