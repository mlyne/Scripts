#!/usr/bin/perl

# Problem 4-3a

use strict;
use NCBI_PowerScripting;

my (%lparams, %links);
my (%sparams);
my ($id, $docsums);

%lparams = read_params();

%links = elink_by_id(%lparams);

$sparams{'db'} = $lparams{'db'};

foreach $id (keys %links) {

   $sparams{'WebEnv'} = $links{$id}{'WebEnv'};
   $sparams{'query_key'} = $links{$id}{'query_key'};
   
   $docsums = esummary(%sparams);
   open (OUT, ">$id.xml");
   print OUT $docsums;
   close OUT;

}
