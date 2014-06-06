#!/usr/bin/perl

# Practical 5, Exercise 1
# For each mouse gene on chromosome 11 that has SNPs, download
#  a) the associated proteins in FASTA format and
#  b) the linked PubMed abstracts

# ESearch - ELink (by id) - EFetch

use strict;
use NCBI_PowerScripting;

my (%sparams, %sresults, %lparams, %links, %mparams, %fparams);

#ESearch
$sparams{'db'} = 'gene';
$sparams{'term'} = 'mouse[orgn]+AND+11[chromosome]+AND+%22gene+snp%22[filter]';
$sparams{'usehistory'} = 'y';

%sresults = esearch(%sparams);

#ELink to protein
$lparams{'dbfrom'} = $sparams{'db'};
$lparams{'db'} = 'protein';
$lparams{'query_key'} = $sresults{'query_key'};
$lparams{'WebEnv'} = $sresults{'WebEnv'};
$lparams{'outfile'} = 'ex5-1_prot';

%links = elink_by_id(%lparams);

#EFetch protein

$fparams{'db'} = $lparams{'db'};
$fparams{'query_key'} = $links{'query_key'};
$fparams{'WebEnv'} = $links{'WebEnv'};
$fparams{'rettype'} = 'fasta';
$fparams{'retmode'} = 'text';
$fparams{'outfile'} = 'ex5-1.faa';

efetch_batch(%fparams);

#ESearch
$sparams{'db'} = 'gene';
$sparams{'term'} = 'mouse[orgn]+AND+11[chromosome]+AND+%22gene+snp%22[filter]';
$sparams{'usehistory'} = 'y';

%sresults = esearch(%sparams);

#ELink to protein
$lparams{'dbfrom'} = $sparams{'db'};
$lparams{'db'} = 'pubmed';
$lparams{'query_key'} = $sresults{'query_key'};
$lparams{'WebEnv'} = $sresults{'WebEnv'};
$lparams{'outfile'} = 'ex5-1_pub';

%links = elink_by_id(%lparams);

#EFetch protein

$fparams{'db'} = $lparams{'db'};
$fparams{'query_key'} = $links{'query_key'};
$fparams{'WebEnv'} = $links{'WebEnv'};
$fparams{'rettype'} = 'abstract';
$fparams{'retmode'} = 'text';
$fparams{'outfile'} = 'ex5-1.abs';

efetch_batch(%fparams);

