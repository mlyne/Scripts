#!/usr/bin/perl

# Practical 3, Exercise 3
# Download SNP DocSums for a file of mouse rs numbers (mouse_snps.in)

# EPost - ESummary

use strict;
use NCBI_PowerScripting;

my (%pparams, %posted, %mparams);

#EPost
$pparams{'db'} = 'snp';
$pparams{'id'} = 'mouse_snps.in';

%posted = epost_file(%pparams);

#ESummary
$mparams{'db'} = $pparams{'db'};
$mparams{'query_key'} = $posted{'query_key'};
$mparams{'WebEnv'} = $posted{'WebEnv'};
$mparams{'outfile'} = 'ex3-3.sum';

esummary(%mparams);


