#!/usr/bin/perl

# EGquery

use strict;
use lib "/home/MIKE/SCRIPTS/EUtils/Scripts";
use NCBI_PowerScripting;

my (%sparams, %sresults);

#EGquery
#$sparams{'db'} = 'pubmed';
$sparams{'term'} = 'nefopam[tiab]+AND+pain[title]';

%sresults = egquery(%sparams);

foreach my $Key (keys %sresults) {	
	print $Key, "\t", $sresults{$Key}, "\n";
}