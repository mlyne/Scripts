#!/usr/bin/perl -w
#
# 30\06\2012 Alastair Crisp
# Get wanted sequences from fasta

use Getopt::Long;
use List::MoreUtils qw/ uniq /;


my $usage = "

Synopsis:

Get_HGT_index -i file.fasta -s Arthropoda_6656_acc.txt [REQUIRED INPUT]
		-o required_seqs.fasta

		
Descriptions:


Options:

  -i The input fasta
  -s The taxon specific list of accessions to exclude


  -o All contigs and their details

";

GetOptions ("i=s" => \$input,
	"s=s" => \$IsProhibited,
	"o=s" => \$output5,
	"help|?" => sub{print $usage; exit();}
	);

if(! $input){
    print $usage;
    exit();
}

if(! $IsProhibited){
    print $usage;
    exit();
}

if(! $output5) {
	$output5 = 'required_seqs.fasta';	
}


sub hashKeyAscendingNum {	#sorts keys by ascending number
   $a <=> $b;
}

sub hashKeyDescendingNum {	#sorts keys by descending number
   $b <=> $a;
}


#Running variables
$to_print = 0;


open(my $ispro,  "<",  $IsProhibited)  or die "Can't open input: $!";
foreach $line (<$ispro>) {
        chomp ($line);
        $key = $line;
        $value = 1;
$prohibited_acc{ $key } = $value;
}
close $ispro or die "$ispro: $!";
open(my $in,  "<",  $input)  or die "Can't open input: $!";

open(my $out5,  ">",  $output5)  or die "Can't open output: $!";

while (<$in>) {
	$line = $_;
	if ($line =~ />\S\S\|(\S\S\S\S\S\S)\|/){
		$key = $1;
		if (exists $prohibited_acc{ $key }){
			$to_print = 1;
			print ($out5 "$line");
		}else{
			$to_print = 0;
		}
	}elsif ($to_print > 0){
		print ($out5 "$line");
	}
}