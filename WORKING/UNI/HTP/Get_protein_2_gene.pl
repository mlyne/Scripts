#!/usr/bin/perl -w
#
# 19\09\2012 Alastair Crisp
# 

use Getopt::Long;
use List::MoreUtils qw/ uniq /;


my $usage = "

Synopsis:

Get_Protein_Names -i fasta
		-o protein_2_gene.tab

		
Descriptions:


Options:

  -i The input Fasta with FBpp to FBgn infor

  -o Tabbed output of FBpp to FBgn

";

GetOptions ("i=s" => \$input,
	"o=s" => \$output,
	"help|?" => sub{print $usage; exit();}
	);

if(! $input){
    print $usage;
    exit();
}

if(! $output) {
	$output = 'protein_2_gene.tab';	
}


sub hashKeyAscendingNum {	#sorts keys by ascending number
   $a <=> $b;
}

sub hashKeyDescendingNum {	#sorts keys by descending number
   $b <=> $a;
}


#Running variables




open(my $in,  "<",  $input)  or die "Can't open input: $!";
open(my $out,  ">",  $output)  or die "Can't open output: $!";

while (<$in>) {
	$line = $_;
	if ($line =~ /(FBpp\d+).+(FBgn\d+)/){
		$protein = $1;
		$gene = $2;
		if (exists $p2g{$protein}){
			print("Warning protein: $protein NOT UNIQUE\n");
		}
		$p2g{$protein} = $gene;
		print($out "$protein\t$gene\n");
	}
}


