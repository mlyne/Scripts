#!/usr/bin/perl

# Practical 5, Exercise 3
# For each gene ID from an input file (genes.in), download in flat file format
# the nucleotide sequences for all known homologous genes. You may assume that
# it is sufficient to index the resulting nucleotide sequences by 
# Homologene IDs.

# EPost - ELink (batch) - ELink (by id) - EFetch

use strict;
use NCBI_PowerScripting;

my (%pparams, %posted, %lparams, %links, %nparams, %nlinks, %fparams);
my @uids;

#EPost
$pparams{'db'} = 'gene';
$pparams{'id'} = 'genes.in';

%posted = epost_file(%pparams);

#ELink from gene to homologene
$lparams{'dbfrom'} = $pparams{'db'};
$lparams{'db'} = 'homologene';
$lparams{'query_key'} = $posted{'query_key'};
$lparams{'WebEnv'} = $posted{'WebEnv'};

%links = elink_batch(%lparams);

#ELink from homologene to nucleotide 

$nparams{'dbfrom'} = $lparams{'db'};
$nparams{'db'} = 'nucleotide';
$nparams{'query_key'} = $links{'query_key'};
$nparams{'WebEnv'} = $links{'WebEnv'};

%nlinks = elink_by_id(%nparams);

#EFetch nucleotide

$fparams{'db'} = $nparams{'db'};
$fparams{'query_key'} = $nlinks{'query_key'};
$fparams{'WebEnv'} = $nlinks{'WebEnv'};
$fparams{'rettype'} = 'gb';
$fparams{'retmode'} = 'text';
$fparams{'outfile'} = 'ex5-3.gb';

efetch_batch(%fparams);
