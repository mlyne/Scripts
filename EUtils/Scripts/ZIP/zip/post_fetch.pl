#!/usr/bin/perl

# EPost - EFetch

use strict;
use NCBI_PowerScripting;

my (%pparams, %posted, %fparams);

#EPost
$pparams{'db'} = 'protein';
$pparams{'id'} = 'proteins.gi';

%posted = epost_file(%pparams);

#EFetch
$fparams{'db'} = $pparams{'db'};
$fparams{'query_key'} = $posted{'query_key'};
$fparams{'WebEnv'} = $posted{'WebEnv'};
$fparams{'rettype'} = 'fasta';
$fparams{'retmode'} = 'text';
$fparams{'outfile'} = 'posted.dat';

efetch_batch(%fparams);


