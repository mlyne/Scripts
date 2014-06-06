#!/usr/bin/perl

#Problem 4-3d

use strict;
use NCBI_PowerScripting;

my (%lparams, %links);
my (%sparams, %results, %sums);
my (%mparams, %mmdbs, %rparams);
my (@datakeys, @sorted, @data);
my $id;

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
$sparams{'verbose'} = 1;

%results = esearch(%sparams);

print "After combining, $results{'count'} records are left.\n";

$mparams{'WebEnv'} = $results{'WebEnv'};
$mparams{'query_key'} = $results{'query_key'};
$mparams{'dbfrom'} = $sparams{'db'};
$mparams{'db'} = 'structure';

%mmdbs = elink_batch(%mparams);

$mmdbs{'db'} = $mparams{'db'};
$mmdbs{'xml'} = 'n';

%sums = esummary(%mmdbs);

@data = keys %sums;

foreach (@data) {
   push(@datakeys, $sums{$_}{'Resolution'});
}

@sorted = @data[sort bynum $[..$#data];

print "MMDB-id\tPDB\tRes\n";

foreach (@sorted) {

   print "$_\t$sums{$_}{'PdbAcc'}\t$sums{$_}{'Resolution'}\n";

}

sub bynum { $datakeys[$a] <=> $datakeys[$b] };
