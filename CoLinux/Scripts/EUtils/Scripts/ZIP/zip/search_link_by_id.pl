#!/usr/bin/perl

# ESearch - ELink (by id)
# UIDs are written to an index file 'links.idx'

use strict;
use NCBI_PowerScripting;

my (%sparams, %sresults, %lparams, %links, %mparams);

#ESearch
$sparams{'db'} = 'protein';
$sparams{'term'} = 'mouse[orgn]+AND+transcarbamylase[title]';
$sparams{'usehistory'} = 'y';

%sresults = esearch(%sparams);

#ELink
$lparams{'dbfrom'} = $sparams{'db'};
$lparams{'db'} = 'gene';
$lparams{'query_key'} = $sresults{'query_key'};
$lparams{'WebEnv'} = $sresults{'WebEnv'};
$lparams{'outfile'} = 'links';

%links = elink_by_id(%lparams);

