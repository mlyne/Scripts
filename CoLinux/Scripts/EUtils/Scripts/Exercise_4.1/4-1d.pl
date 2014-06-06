#!/usr/bin/perl

#Problem 4-1d

use strict;
use NCBI_PowerScripting;

my (%params, %results);
my (%lparams, %links);
my (%fparams);

%params = read_params();

%results = esearch(%params);

$lparams{'WebEnv'} = $results{'WebEnv'};
$lparams{'query_key'} = $results{'query_key'};
$lparams{'dbfrom'} = $params{'db'};
$lparams{'db'} = 'pubmed';

%links = elink_batch(%lparams);

$fparams{'db'} = $lparams{'db'};
$fparams{'retmode'} = 'text';
$fparams{'rettype'} = 'abstract';

$fparams{'query_key'} = $links{'query_key'};
$fparams{'WebEnv'} = $links{'WebEnv'};
$fparams{'outfile'} = 'problem1d.abs';

efetch_batch(%fparams);

