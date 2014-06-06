#!/usr/bin/perl

# ELink (batch) - ESummary

use strict;
use NCBI_PowerScripting;

my (%mparams, %lparams, %links);

#ELink

$lparams{'dbfrom'} = 'nucleotide';
$lparams{'db'} = 'protein';
$lparams{'id'} = '56181373,56181375,56181371,21614549';

%links = elink_batch(%lparams);

#ESummary

$mparams{'db'} = $lparams{'db'};
$mparams{'query_key'} = $links{'query_key'};
$mparams{'WebEnv'} = $links{'WebEnv'};
$mparams{'outfile'} = 'docsums';

esummary(%mparams);
