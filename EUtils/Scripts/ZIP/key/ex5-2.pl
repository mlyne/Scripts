#!/usr/bin/perl

# Practical 5, Exercise 2
# Download DocSums for all proteins that contain both conserved domains
# represented by PSSM-IDs 28079 and 5392. 
#  (Hint: Set $params{'get_uids'} in elink_by_id to 'n'.)

# ELink (by id) - ESearch

# The trick here is to combine the sets of proteins linked to each CD with AND
# using ESearch. This is one case where setting 'get_uids' to 'n' in elink_by_id
# is useful, since this gives you two query keys (one for each set of proteins)
# and a common web environment that can be passed to esearch.

use strict;
use NCBI_PowerScripting;

my (%sparams, %sresults, %lparams, %links, %mparams);


#ELink

$lparams{'dbfrom'} = 'cdd';
$lparams{'db'} = 'protein';
$lparams{'id'} = '28079,5392';
$lparams{'get_uids'} = 'n';

%links = elink_by_id(%lparams);

#ESearch to combine sets
$sparams{'db'} = $lparams{'db'};
$sparams{'usehistory'} = 'y';
$sparams{'term'} = "%23$links{'28079'}{'query_key'}+AND+%23$links{'5392'}{'query_key'}";
$sparams{'WebEnv'} = $links{'28079'}{'WebEnv'};

%sresults = esearch(%sparams);

$mparams{'db'} = $sparams{'db'};
$mparams{'query_key'} = $sresults{'query_key'};
$mparams{'WebEnv'} = $sresults{'WebEnv'};
$mparams{'outfile'} = 'ex5-2.sum';

esummary(%mparams);
