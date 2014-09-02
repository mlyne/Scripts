#!/usr/bin/perl -w
#
# 18\09\2012 Alastair Crisp
# Get wanted sequences from fasta

use Getopt::Long;
use List::MoreUtils qw/ uniq /;


my $usage = "

Synopsis:

Get_Protein_Names -i mcl_output -y flymine_proteinnames.tsv -u wholeuniprot_index.tab [REQUIRED INPUT]
		-o protein_groups.tab

		
Descriptions:


Options:

  -i The input mcl
  -y The list of protein names
  -u Uniprot name files

  -o Proteins in groups with names

";

GetOptions ("i=s" => \$input,
	"y=s" => \$IsProhibited,
	"u=s" => \$Uniprot,
	"o=s" => \$output,
	"help|?" => sub{print $usage; exit();}
	);

if(! $input){
    print $usage;
    exit();
}
if(! $Uniprot){
    print $usage;
    exit();
}

if(! $IsProhibited){
    print $usage;
    exit();
}

if(! $output) {
	$output = 'protein_groups.tab';	
}


sub hashKeyAscendingNum {	#sorts keys by ascending number
   $a <=> $b;
}

sub hashKeyDescendingNum {	#sorts keys by descending number
   $b <=> $a;
}


#Running variables
$index = 1;

open(my $in2,  "<",  $Uniprot)  or die "Can't open input: $!";
foreach $line (<$in2>) {
	if ($line =~ /(\S+)\s+(\S+)\s+(.+)/){
		$uniprot = $1;
#		$entry = $2;
		$protein = $3;
		chomp($protein);
		$uniprot_ref{$uniprot} = $protein;
	}
}
close $in2 or die "$in2: $!";

print("Loaded UniProt names\n");

open(my $ispro,  "<",  $IsProhibited)  or die "Can't open input: $!";
foreach $line (<$ispro>) {
	if ($line =~ /(\S+)\s+(\S+)\s+(.+)/){
		$protein = $1;
		$uniprot = $2;
		$name = $3;
		chomp($name);
		if (exists $uniprot_ref{$uniprot}){
			$name2 = $uniprot_ref{$uniprot};
			$name = $name . "\t" . $name2;
#			print("$name2\n");
		}
		$flybase_ref{$protein} = $name;
	}
}
close $ispro or die "$ispro: $!";



open(my $in,  "<",  $input)  or die "Can't open input: $!";
open(my $out,  ">",  $output)  or die "Can't open output: $!";

while (<$in>) {
	$line = $_;
	@homologs = split(/\s/, $line);
#	print($out "$homologs[1]\n");
	for($i = 0; $i < scalar(@homologs); $i++) {
		if (exists $flybase_ref{$homologs[$i]}){
			$name = $flybase_ref{$homologs[$i]};
		}else{	
			$name = "";
		}
		print($out "$homologs[$i]\t$index\t$name\n");
	}
	$index++;
}


