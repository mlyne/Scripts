#!/usr/bin/perl

# ELink (by id) - EFetch

use strict;
use NCBI_PowerScripting;

my (%lparams, %links, %fparams);

#ELink
$lparams{'dbfrom'} = 'nucleotide';
$lparams{'db'} = 'protein';
$lparams{'id'} = '56181373,56181375,56181371,21614549';

%links = elink_by_id(%lparams);

#EFetch

$fparams{'db'} = $lparams{'db'};
$fparams{'query_key'} = $links{'query_key'};
$fparams{'WebEnv'} = $links{'WebEnv'};
$fparams{'rettype'} = 'fasta';
$fparams{'retmode'} = 'text';
$fparams{'outfile'} = 'fasta.dat';

efetch_batch(%fparams);
