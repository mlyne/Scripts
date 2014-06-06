#!/usr/bin/perl

# Problem 4-3b

use strict;
use NCBI_PowerScripting;

my (%lparams, %links);
my (%sparams, %results);
my ($id, $sums);

%lparams = read_params();

%links = elink_by_id(%lparams);

# Note: elink_by_id will group a maximum of 20 query keys to the 
# same WebEnv, so this code only works for an input id list of 
# 20 or fewer UIDs

foreach $id (keys %links) {

  $sparams{'term'} .= "%23$links{$id}{'query_key'}+AND+";
  $sparams{'WebEnv'} = $links{$id}{'WebEnv'};
  
}

$sparams{'term'} = substr($sparams{'term'}, 0, -5);
$sparams{'db'} = $lparams{'db'};
$sparams{'usehistory'} = 'y';

%results = esearch(%sparams);

print "After combining, $results{'count'} records are left.\n";

$sparams{'WebEnv'} = $results{'WebEnv'};
$sparams{'query_key'} = $results{'query_key'};

$sums = esummary(%sparams);

open (OUT, ">problem4-3b.out");
print OUT $sums;
close OUT;
