#!/usr/bin/perl

# ELink (batch) - EFetch

use strict;
use NCBI_PowerScripting;

my (%fparams, %lparams, %links);

#ELink

$lparams{'dbfrom'} = 'nucleotide';
$lparams{'db'} = 'protein';
$lparams{'id'} = '56181373,56181375,56181371,21614549';

%links = elink_batch(%lparams);

#EFetch

$fparams{'db'} = $lparams{'db'};
$fparams{'query_key'} = $links{'query_key'};
$fparams{'WebEnv'} = $links{'WebEnv'};
$fparams{'rettype'} = 'fasta';
$fparams{'retmode'} = 'text';
$fparams{'outfile'} = 'fasta.out';

efetch_batch(%fparams);
