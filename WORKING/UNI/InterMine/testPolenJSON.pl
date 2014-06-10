#!/usr/bin/perl
#
#

use strict;
use warnings;
use feature ':5.12';
use JSON;
use Data::Dumper;

$Data::Dumper::Indent = 3;

my $part_name = "testPart";
my $part_sequence = "ATGATGATGATG";
my $organism = "E. coli";
my $chromosome = "NC_00913.2";
my $start = "2866804";
my $end = "2866840";
my $strand = "-1";
my $gene_id = "EG11149";
my $data_set = "E. coli str. K-12 substr. MG1655";

my $blast_results = [ "nlpD TTCAGTAGGGTGCCTTGCACGGTAATTATGTCACTGG NC_000913.2:2866804..2866840 -1" ];

my $expression_results = [
			[-1.618,6.598,8.139,"cold stress timepoint 4"], 
			[-1.54,11.982,8.216,"cold stress timepoint 6"],
			[-1.516,3.499,8.24,"cold stress timepoint 5"],
			[-1.109,6.241,8.647,"cold stress timepoint 7"],
];

#print @{ $expression_results->[0] }[3], "\n";

my %processed = map {$_->[3] => {log2_fold_change => $_->[0], expression => $_->[1], variation_cooefficient => $_->[2]}} @$expression_results;

my $synbio_result = {
	'part' => [
            { type => 'promoter',  
	      name => $part_name, 
	      sequence => "$part_sequence" },
        ],
        'genome_hit' => [
            { genome_hit => \1,  
	      organism => $organism, 
	      location =>
			{ chromosome => $chromosome,
			  start => $start,
			  end => $end,
			  strand => $strand },
	      blast_results => $blast_results,
	    },
	],
	  'synbiomine_search' => [
            {
	      gene_hit => \1, 
	      gene_id => $gene_id,
	      data_set => $data_set,  
	      expression_hit => \1, 
	      expression_result => \%processed,
	    }
       ],
 };

my $json_text = encode_json $synbio_result;

say $json_text;