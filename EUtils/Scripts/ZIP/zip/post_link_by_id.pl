#!/usr/bin/perl

# EPost - ELink (by id)
# UIDs are written to an index file 'links.idx'

use strict;
use NCBI_PowerScripting;

my (%pparams, %posted, %lparams, %links);

#EPost
$pparams{'db'} = 'protein';
$pparams{'id'} = 'proteins.gi';

%posted = epost_file(%pparams);

#ELink
$lparams{'dbfrom'} = $pparams{'db'};
$lparams{'db'} = 'nucleotide';
$lparams{'query_key'} = $posted{'query_key'};
$lparams{'WebEnv'} = $posted{'WebEnv'};
$lparams{'outfile'} = 'links';

%links = elink_by_id(%lparams);


