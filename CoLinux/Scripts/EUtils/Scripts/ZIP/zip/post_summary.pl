#!/usr/bin/perl

# EPost - ESummary

use strict;
use NCBI_PowerScripting;

my (%pparams, %posted, %mparams);

#EPost
$pparams{'db'} = 'protein';
$pparams{'id'} = 'proteins.gi';

%posted = epost_file(%pparams);

#ESummary
$mparams{'db'} = $pparams{'db'};
$mparams{'query_key'} = $posted{'query_key'};
$mparams{'WebEnv'} = $posted{'WebEnv'};
$mparams{'outfile'} = 'posted.sum';

esummary(%mparams);


