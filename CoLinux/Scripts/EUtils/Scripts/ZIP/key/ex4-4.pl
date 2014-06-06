#!/usr/bin/perl

# Practical 4, Exercise 4
# Given a file of protein GIs (prot_gi.in), determine how many have molecular weights of 220-225 kDa

# EPost - ESearch

use strict;
use NCBI_PowerScripting;

my (%pparams, %posted, %sparams, %sresults);
my @uids;

#EPost
$pparams{'db'} = 'protein';
$pparams{'id'} = 'prot_gi.in';

%posted = epost_file(%pparams);

#ESearch
$sparams{'db'} = $pparams{'db'};
$sparams{'term'} = "%23$posted{'query_key'}+AND+220000:225000[molwt]";
$sparams{'WebEnv'} = $posted{'WebEnv'};
$sparams{'usehistory'} = 'y';

%sresults = esearch(%sparams);

print "Found $sresults{'count'} proteins that are 220-225 kDa.\n";
