#!/usr/bin/perl

# ELink (by id) - ESummary

use strict;
use NCBI_PowerScripting;

my (%lparams, %links, %mparams);

#ELink
$lparams{'dbfrom'} = 'nucleotide';
$lparams{'db'} = 'protein';
$lparams{'id'} = '56181373,56181375,56181371,21614549';
$lparams{'outfile'} = 'links';

%links = elink_by_id(%lparams);

#ESummary

$mparams{'db'} = $lparams{'db'};
$mparams{'query_key'} = $links{'query_key'};
$mparams{'WebEnv'} = $links{'WebEnv'};
$mparams{'outfile'} = 'docsums';

esummary(%mparams);
