
# An example script demonstrating the use of BioMart API.
# This perl API representation is only available for configuration versions >=  0.5 
use strict;
use BioMart::Initializer;
use BioMart::Query;
use BioMart::QueryRunner;

my $confFile = "/home/ml590/src/biomart-perl/conf/martReg_ML.xml";
#
# NB: change action to 'clean' if you wish to start a fresh configuration  
# and to 'cached' if you want to skip configuration step on subsequent runs from the same registry
#

my $action='clean';
my $initializer = BioMart::Initializer->new('registryFile'=>$confFile, 'action'=>$action);
my $registry = $initializer->getRegistry;

my $query = BioMart::Query->new('registry'=>$registry,'virtualSchemaName'=>'default');

		
	$query->setDataset("hm27_variation");
	$query->addFilter("allele_freq", ["0.05"]);
	$query->addFilter("chrom", ["chr21"]);
	$query->addAttribute("chrom");
	$query->addAttribute("start");
	$query->addAttribute("strand");
	$query->addAttribute("marker1");
	$query->addAttribute("pop_code_genotype");
	$query->addAttribute("alleles");
	$query->addAttribute("ref_allele_freq");
	$query->addAttribute("ref_allele_count");
	$query->addAttribute("other_allele_freq");
	$query->addAttribute("other_allele_count");
	$query->addAttribute("total_allele_count");

$query->formatter("TSV");

my $query_runner = BioMart::QueryRunner->new();
############################## GET COUNT ############################
# $query->count(1);
# $query_runner->execute($query);
# print $query_runner->getCount();
#####################################################################


############################## GET RESULTS ##########################
# to obtain unique rows only
# $query_runner->uniqueRowsOnly(1);

$query_runner->execute($query);
$query_runner->printHeader();
$query_runner->printResults();
$query_runner->printFooter();
#####################################################################
