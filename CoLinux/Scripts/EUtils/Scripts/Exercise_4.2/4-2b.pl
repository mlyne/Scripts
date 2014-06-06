#!/usr/bin/perl

#Problem 4-2b

use strict;
use NCBI_PowerScripting;

my (%params, %results);
my (%lparams, %links);
my (%sparams, %fparams, %sresults);

%params = read_params();

%results = epost_file(%params);

$sparams{'WebEnv'} = $results{'WebEnv'};
$sparams{'term'} = "%23" . "$results{'query_key'}";
$sparams{'term'} .= "+AND+adenoviridae[orgn]+AND+srcdb+refseq+reviewed[prop]";
$sparams{'usehistory'} = 'y';
$sparams{'db'} = $params{'db'};

%sresults = esearch(%sparams);

print "After filtering, $sresults{'count'} records remain.\n";

$lparams{'dbfrom'} = $sparams{'db'};
$lparams{'db'} = 'gene';
$lparams{'query_key'} = $sresults{'query_key'};
$lparams{'WebEnv'} = $sresults{'WebEnv'};

%links = elink_by_id(%lparams);

$fparams{'db'} = $lparams{'db'};

foreach (keys %links) {

$fparams{'query_key'} = $links{$_}{'query_key'};
$fparams{'WebEnv'} = $links{$_}{'WebEnv'};
$fparams{'retmode'} = 'xml';
$fparams{'outfile'} = "$_" . '.xml';

efetch_batch(%fparams);

}
