#!/usr/bin/perl

# Practical 5, Exercise 4
# Given a file of protein accessions (prot_acc.in), determine how many of them 
# have SNPs with genotype data.

# ESearch - ESearch
# This example limits the results of the first search with the query in $term2

# Here the trick is to use ESearch to load the accessions onto the history, and then use 
# ESearch again to limit the set to human sequences. When searching with accessions, it is best
# to limit each accession to the primary accession field [pacc] to be sure that you get only that
# record. These terms must then be combined with OR. As you should see from the results, if an accession is not current, it will not
# be retrieved if limited to [pacc] thereby alerting you that it is no longer active.

# To run this script, note that the input file must be supplied on the command line:
# perl ex5-4.pl prot_acc.in

use strict;
use NCBI_PowerScripting;

my (%sparams, %sresults, %sparams2, %sresults2);
my (@accs, @final);
my $q;
my $term2 = '+AND+protein+snp+genegenotype[filter]';

# read input file
open (INPUT, "$ARGV[0]") || die "Can't open $ARGV[0]!\n";

while (<INPUT>) {

   chomp;
   $q = $_ . '[pacc]';
   push (@accs, $q);

}

#ESearch 1

$sparams{'db'} = 'protein';
$sparams{'usehistory'} = 'y';
$sparams{'term'} = join('+OR+', @accs);

%sresults = esearch(%sparams);

print "$sresults{'count'} accessions loaded onto the history.\n";

#ESearch 2
$sparams2{'db'} = $sparams{'db'};
$sparams2{'term'} = "%23$sresults{'query_key'}" . $term2;
$sparams2{'WebEnv'} = $sresults{'WebEnv'};
$sparams2{'usehistory'} = 'y';

%sresults2 = esearch(%sparams2);

print "$sresults2{'count'} accessions have SNP genotype data.\n";
