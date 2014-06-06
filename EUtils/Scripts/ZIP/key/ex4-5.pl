#!/usr/bin/perl

# Practical 4, Exercise 5
# For the gene IDs 12874 and 252868, find the rs numbers of all nonsynonymous SNPs for each gene

# ELink (by id) - ESearch

use strict;
use NCBI_PowerScripting;

my (%sparams, %sresults, %lparams, %links, %output, %getids);
my @uids;
my $id;
my $term = "+AND+coding+nonsynon[function+class]";

#ELink

$lparams{'dbfrom'} = 'gene';
$lparams{'db'} = 'snp';
$lparams{'id'} = '12874,252868';

%links = elink_by_id(%lparams);


#ESearch for each id
$sparams{'db'} = $lparams{'db'};
$sparams{'usehistory'} = 'y';
$sparams{'term'} = "%23$links{'query_key'}" . $term;
$sparams{'WebEnv'} = $links{'WebEnv'};
$sparams{'infile'} = "$lparams{'dbfrom'}" . '_' . "$lparams{'db'}" . '.idx';

%sresults = esearch_links(%sparams);

