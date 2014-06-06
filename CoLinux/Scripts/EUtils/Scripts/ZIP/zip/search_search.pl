#!/usr/bin/perl

# ESearch - ESearch
# This example limits the results of the first search with the query in $term2

use strict;
use NCBI_PowerScripting;

my (%sparams, %sresults, %sparams2, %sresults2);
my @final;
my $num;
my $term2 = '+AND+srcdb+refseq[prop]';

#ESearch 1
$sparams{'db'} = 'protein';
$sparams{'term'} = 'mouse[orgn]+AND+transcarbamylase[title]';
$sparams{'usehistory'} = 'y';

%sresults = esearch(%sparams);

print "The first search returned $sresults{'count'} records.\n";

#ESearch 2
$sparams2{'db'} = $sparams{'db'};
$sparams2{'term'} = "%23$sresults{'query_key'}" . $term2;
$sparams2{'WebEnv'} = $sresults{'WebEnv'};
$sparams2{'usehistory'} = 'y';

%sresults2 = esearch(%sparams2);
$sresults2{'db'} = $sparams2{'db'};

@final = get_uids(%sresults2);
$num = @final;

print "The second search returned $num records:\n";
foreach (@final) { print "$_ "; }
print "\n";
