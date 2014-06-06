#!/usr/bin/perl

#Problem 4-1a

use strict;
use NCBI_PowerScripting;

my (%params, %results);

%params = read_params();

%results = esearch(%params);

$params{'WebEnv'} = $results{'WebEnv'};
$params{'query_key'} = $results{'query_key'};

efetch_batch(%params);
