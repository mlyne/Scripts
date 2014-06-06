#!/usr/bin/perl

# Practical 3, Exercise 4
# Download gene XML records for a file of gene IDs (genes.in)

# EPost - EFetch

use strict;
use NCBI_PowerScripting;

my (%pparams, %posted, %fparams);

#EPost
$pparams{'db'} = 'gene';
$pparams{'id'} = 'genes.in';

%posted = epost_file(%pparams);

#EFetch
$fparams{'db'} = $pparams{'db'};
$fparams{'query_key'} = $posted{'query_key'};
$fparams{'WebEnv'} = $posted{'WebEnv'};
$fparams{'rettype'} = 'xml';
$fparams{'retmode'} = 'xml';
$fparams{'outfile'} = 'ex3-4.dat';

efetch_batch(%fparams);


