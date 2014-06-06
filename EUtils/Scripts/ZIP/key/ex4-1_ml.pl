#!/usr/bin/perl

# Practical 4, Exercise 1
# Given a file of protein GIs (prot_gi.in), download a single set of linked PubMed IDs

# EPost - ELink (batch)
# UIDs are recovered with get_uids

use strict;
use lib "/home/MIKE/SCRIPTS/EUtils/Scripts";
use NCBI_PowerScripting;

my (%pparams, %posted, %lparams, %links);
my @uids;

#EPost
$pparams{'db'} = 'protein';
$pparams{'id'} = '../zip/prot_gi.in';

%posted = epost_file(%pparams);

#ELink
$lparams{'dbfrom'} = $pparams{'db'};
$lparams{'db'} = 'pubmed';
$lparams{'query_key'} = $posted{'query_key'};
$lparams{'WebEnv'} = $posted{'WebEnv'};

%links = elink_batch(%lparams);

#Recover UIDs

$links{'db'} = $lparams{'db'};

@uids = get_uids(%links);

open (OUTPUT, ">ex4-1.out");
foreach (@uids) { print OUTPUT "$_\n";}
close OUTPUT;
