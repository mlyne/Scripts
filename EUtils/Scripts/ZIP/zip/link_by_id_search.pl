#!/usr/bin/perl

# ELink (by id) - ESearch

use strict;
use NCBI_PowerScripting;
use Data::Dumper;

my (%sparams, %sresults, %lparams, %links, %output, %getids);
my @uids;
my $id;
my $term = "+AND+srcdb+refseq[prop]";

#ELink

$lparams{'dbfrom'} = 'nucleotide';
$lparams{'db'} = 'protein';
$lparams{'id'} = '56181373,56181375,56181371,21614549';

%links = elink_by_id(%lparams);


#ESearch for each id
$sparams{'db'} = $lparams{'db'};
$sparams{'usehistory'} = 'y';
$sparams{'term'} = "%23$links{'query_key'}" . $term;
$sparams{'WebEnv'} = $links{'WebEnv'};
$sparams{'infile'} = "$lparams{'dbfrom'}" . '_' . "$lparams{'db'}" . '.idx';

%sresults = esearch_links(%sparams);

