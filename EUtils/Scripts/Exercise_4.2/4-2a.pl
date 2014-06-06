#!/usr/bin/perl

#Problem 4-2a

use strict;
use NCBI_PowerScripting;

my (%params, %results);
my (%sparams, %sresults);

%params = read_params();

%results = epost_file(%params);

$sparams{'WebEnv'} = $results{'WebEnv'};
$sparams{'term'} = "%23" . "$results{'query_key'}";
$sparams{'term'} .= "+AND+adenoviridae[orgn]+AND+srcdb+refseq+reviewed[prop]";
$sparams{'usehistory'} = 'y';
$sparams{'db'} = $params{'db'};

%sresults = esearch(%sparams);

print "After filtering, $sresults{'count'} records remain.\n";
