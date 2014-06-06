#!/usr/bin/perl

# Practical 4, Exercise 3
# Given a file of gene IDs (genes.in), download GEO profile IDs linked to each gene

# EPost - ELink (by id)

use strict;
use NCBI_PowerScripting;

my (%pparams, %posted, %lparams, %links);

#EPost
$pparams{'db'} = 'gene';
$pparams{'id'} = 'genes.in';

%posted = epost_file(%pparams);

#ELink
$lparams{'dbfrom'} = $pparams{'db'};
$lparams{'db'} = 'geo';
$lparams{'query_key'} = $posted{'query_key'};
$lparams{'WebEnv'} = $posted{'WebEnv'};
$lparams{'outfile'} = 'ex4-3';

%links = elink_by_id(%lparams);


