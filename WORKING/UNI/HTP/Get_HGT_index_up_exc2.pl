#!/usr/bin/perl -w
#
# 24\02\2012 Alastair Crisp
# Get HGT_index for a set of data

use Getopt::Long;
use List::MoreUtils qw/ uniq /;


my $usage = "

Synopsis:

Get_HGT_index -i outputqall.blast -s Arthropoda_6656_acc.txt [REQUIRED INPUT]
		-t threshold -r lower threshold for indeterminate [INPUTS WITH DEFAULTS]
		-h acc_metswissprot_index.tab -x acc_bacuniprot_index.tab -y acc_arcuniprot_index.tab 
		-z acc_fununiprot_index.tab -l acc_plauniprot_index.tab -n euk_metuniprot_index.tab [classes - INPUTS WITH DEFAULTS]
		-o contig_details.txt [DEFAULT OUTPUTS]

		
Descriptions:


Options:

  -i The input blast results file
  -s The taxon specific list of accessions to exclude

  -h File with accession numbers of metazoan proteins
  -x File with accession numbers of bacterial proteins
  -y File with accession numbers of archaea proteins
  -z File with accession numbers of fungal proteins
  -l File with accession numbers of plant proteins
  -n File with accession numbers of other eukaryotic proteins
  -o All contigs and their details
  -t threshold for HGT index
  -r Threshold for HGT index indeterminate status (between this and above goes to indeterminate), defaults to 0
";

GetOptions ("i=s" => \$input,
	"h=s" => \$IsMet,
	"x=s" => \$IsBac,
	"y=s" => \$IsArc,
	"z=s" => \$IsFun,
	"l=s" => \$IsPla,
	"n=s" => \$IsEuk,
	"s=s" => \$IsProhibited,
	"o=s" => \$output5,
	"t=s" => \$threshold,
	"r=s" => \$threshold2,
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


if(! $IsMet) {
	$IsMet = '/local/hgt_in_model_organisms/Databases/uniprot/acc_metuniprot_index.tab';
}

if(! $IsBac) {
	$IsBac = '/local/hgt_in_model_organisms/Databases/uniprot/acc_bacuniprot_index.tab';
}

if(! $IsArc) {
	$IsArc = '/local/hgt_in_model_organisms/Databases/uniprot/acc_arcuniprot_index.tab';
}

if(! $IsFun) {
	$IsFun = '/local/hgt_in_model_organisms/Databases/uniprot/acc_fununiprot_index.tab';
}

if(! $IsPla) {
	$IsPla = '/local/hgt_in_model_organisms/Databases/uniprot/acc_plauniprot_index.tab';
}

if(! $IsEuk) {
	$IsEuk = '/local/hgt_in_model_organisms/Databases/uniprot/acc_eukuniprot_index.tab';
}

if(! $threshold) {
	$threshold = 30;
}

if(! $threshold2) {
	$threshold2 = 0;
}

if(! $output5) {
	$output5 = 'contig_details' . $threshold . '_' . $threshold2 . '.txt';	
}


sub hashKeyAscendingNum {	#sorts keys by ascending number
   $a <=> $b;
}

sub hashKeyDescendingNum {	#sorts keys by descending number
   $b <=> $a;
}

#Stuff to change
$e_value = 0.00001;


#Running variables
#Contig number indexed
my %ac_hash = ();		#contig number to accession number	for first hit
my %ac_hash3 = ();		#contig number to HGT index value
my %metazoan_bitscore = ();	#contig indexed
my %nonmetazoan_bitscore = ();

#Accession number indexed
my %metazoan_acc = ();		#accession numbers of metazoan proteins
my %bacteria_acc = ();		#accession numbers of bacterial proteins
my %archaea_acc = ();		#accession numbers of archaea proteins
my %fungi_acc = ();		#accession numbers of fungal proteins
my %plant_acc = ();		#accession numbers of plant proteins
my %othereuk_acc = ();		#accession numbers of other eukaryotic proteins

#Other
$count = 0;			#nHGT 
$count2 = 0;			#nHGT with no metazoan hits
$count_b = 0;			#nHGT bac
$count_a = 0;			#nHGT arc
$count_p = 0;			#nHGT pla
$count_f = 0;			#nHGT fun
$count_e = 0;			#nHGT other euk
$count_v = 0;			#nHGT vir
$total = 0;



# Populate protein classes - Accession numbers for metazoan proteins
open(my $ismetazoan,  "<",  $IsMet)  or die "Can't open input: $!";
foreach $line (<$ismetazoan>) {
        chomp ($line);
        $key = $line;
        $value = 1;
$metazoan_acc{ $key } = $value;
}
close $ismetazoan or die "$ismetazoan: $!";

open(my $ispro,  "<",  $IsProhibited)  or die "Can't open input: $!";
foreach $line (<$ispro>) {
        chomp ($line);
        $key = $line;
        $value = 1;
$prohibited_acc{ $key } = $value;
}
close $ispro or die "$ispro: $!";

open(my $isbacteria,  "<",  $IsBac)  or die "Can't open input: $!";
foreach $line (<$isbacteria>) {
        chomp ($line);
        $key = $line;
        $value = 1;
$bacteria_acc{ $key } = $value;
}
close $isbacteria or die "$isbacteria: $!";

open(my $isarchaea,  "<",  $IsArc)  or die "Can't open input: $!";
foreach $line (<$isarchaea>) {
        chomp ($line);
        $key = $line;
        $value = 1;
$archaea_acc{ $key } = $value;
}
close $isarchaea or die "$isarchaea: $!";

open(my $isfungi,  "<",  $IsFun)  or die "Can't open input: $!";
foreach $line (<$isfungi>) {
        chomp ($line);
        $key = $line;
        $value = 1;
$fungi_acc{ $key } = $value;
}
close $isfungi or die "$isfungi: $!";

open(my $isplant,  "<",  $IsPla)  or die "Can't open input: $!";
foreach $line (<$isplant>) {
        chomp ($line);
        $key = $line;
        $value = 1;
$plant_acc{ $key } = $value;
}
close $isplant or die "$isplant: $!";

open(my $isothereuk,  "<",  $IsEuk)  or die "Can't open input: $!";
foreach $line (<$isothereuk>) {
        chomp ($line);
        $key = $line;
        $value = 1;
$othereuk_acc{ $key } = $value;
}
close $isothereuk or die "$isothereuk: $!";


# Populate ac_hash and ac_hash3
open(my $in,  "<",  $input)  or die "Can't open input: $!";

open(my $out5,  ">",  $output5)  or die "Can't open output: $!";

while (<$in>) {
	$line = $_;
	if ($_ =~ /(\S+)\t\w\w\|([A-Z][A-Z|0-9]{5})/) {		
		$Blast_Contig = $1;
		$Blast_Acc = $2;
#		$line =~ /(\S+)\t([\d|.]+)$/;
		$line =~ /\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)\s+(\S+)/;
		$Blast_E = $1;
		$Blast_Bitscore = $2;
#		print("$Blast_E\n");

		if ($Blast_E <= $e_value){
#		print("$Blast_E\n");
		if (exists $prohibited_acc{$Blast_Acc}){	#then ignore
		}else{
			if (exists $ac_hash3{$Blast_Contig}) {		#then we already have two hits for this
			}else{
				if (exists $metazoan_acc{$Blast_Acc}) {	#if true metazoan, if false non-metazoan			
					if (exists $metazoan_bitscore{$Blast_Contig}) {		#then we already had a met hit
					}else{
						$metazoan_bitscore{$Blast_Contig} = $Blast_Bitscore;
						if (exists $nonmetazoan_bitscore{$Blast_Contig}) { #then nonmet is best hit
							#Calculate HGT index
							$ac_hash3{$Blast_Contig} = $nonmetazoan_bitscore{$Blast_Contig} - $metazoan_bitscore{$Blast_Contig};
							
							if ($ac_hash3{$Blast_Contig} > $threshold) {	#add to HGT
		
								if (exists $bacteria_acc{$ac_hash{$Blast_Contig}}) {
									print ($out5 "$Blast_Contig\t$Blast_Acc\t$ac_hash{$Blast_Contig}\t$metazoan_bitscore{$Blast_Contig}\t$nonmetazoan_bitscore{$Blast_Contig}\t$ac_hash3{$Blast_Contig}\tBacteria\n");	
									$count_b++;		
								}elsif ($archaea_acc{$ac_hash{$Blast_Contig}}) {
									print ($out5 "$Blast_Contig\t$Blast_Acc\t$ac_hash{$Blast_Contig}\t$metazoan_bitscore{$Blast_Contig}\t$nonmetazoan_bitscore{$Blast_Contig}\t$ac_hash3{$Blast_Contig}\tArchea\n");	
									$count_a++;		
								}elsif ($fungi_acc{$ac_hash{$Blast_Contig}}) {
									print ($out5 "$Blast_Contig\t$Blast_Acc\t$ac_hash{$Blast_Contig}\t$metazoan_bitscore{$Blast_Contig}\t$nonmetazoan_bitscore{$Blast_Contig}\t$ac_hash3{$Blast_Contig}\tFungi\n");	
									$count_f++;		
								}elsif ($plant_acc{$ac_hash{$Blast_Contig}}) {
									print ($out5 "$Blast_Contig\t$Blast_Acc\t$ac_hash{$Blast_Contig}\t$metazoan_bitscore{$Blast_Contig}\t$nonmetazoan_bitscore{$Blast_Contig}\t$ac_hash3{$Blast_Contig}\tPlant\n");	
									$count_p++;		
								}elsif ($othereuk_acc{$ac_hash{$Blast_Contig}}) {
									print ($out5 "$Blast_Contig\t$Blast_Acc\t$ac_hash{$Blast_Contig}\t$metazoan_bitscore{$Blast_Contig}\t$nonmetazoan_bitscore{$Blast_Contig}\t$ac_hash3{$Blast_Contig}\tOther Eukarote\n");	
									$count_e++;		
								}else{
									print ($out5 "$Blast_Contig\t$Blast_Acc\t$ac_hash{$Blast_Contig}\t$metazoan_bitscore{$Blast_Contig}\t$nonmetazoan_bitscore{$Blast_Contig}\t$ac_hash3{$Blast_Contig}\tVirus\n");	
									$count_v++;		
								}								

								$count++;
							}else{
								print($out5 "$Blast_Contig\t$Blast_Acc\t$ac_hash{$Blast_Contig}\t$metazoan_bitscore{$Blast_Contig}\t$nonmetazoan_bitscore{$Blast_Contig}\t$ac_hash3{$Blast_Contig}\tNA\n");			
							}
							$total++;
						}else{
							$ac_hash{$Blast_Contig} = $Blast_Acc;
						}
					}
				}else{
					if (exists $nonmetazoan_bitscore{$Blast_Contig}) {	#then we already had a non-met hit
					}else{
						$nonmetazoan_bitscore{$Blast_Contig} = $Blast_Bitscore;
						if (exists $metazoan_bitscore{$Blast_Contig}) { #then met is best hit
							#Calculate HGT index
							$ac_hash3{$Blast_Contig} = $nonmetazoan_bitscore{$Blast_Contig} - $metazoan_bitscore{$Blast_Contig};
						
							print($out5 "$Blast_Contig\t$ac_hash{$Blast_Contig}\t$Blast_Acc\t$metazoan_bitscore{$Blast_Contig}\t$nonmetazoan_bitscore{$Blast_Contig}\t$ac_hash3{$Blast_Contig}\tNA\n");		
							$total++;
						}else{
							$ac_hash{$Blast_Contig} = $Blast_Acc;
						}
					}
				}
			}	
		}
		}
	}
}

close $in or die "$in: $!";


#Calculate HGT for where only met or non-met and get the GO stuff for these
foreach $key ((keys(%metazoan_bitscore))) {
	if (exists $nonmetazoan_bitscore{$key}) {
	}else{
		$ac_hash3{$key} = - $metazoan_bitscore{$key};
		print ($out5 "$key\t$ac_hash{$key}\tNA\t$metazoan_bitscore{$key}\tNA\t$ac_hash3{$key}\tNA\n");		
		$total++;					
	}
}
foreach $key ((keys(%nonmetazoan_bitscore))) {
	if (exists $metazoan_bitscore{$key}) {
	}else{
		$total++;
		$ac_hash3{$key} = $nonmetazoan_bitscore{$key};							
		if ($ac_hash3{$key} > $threshold) {	#add to HGT
			if (exists $bacteria_acc{$ac_hash{$key}}) {
				print ($out5 "$key\tNA\t$ac_hash{$key}\t0\t$nonmetazoan_bitscore{$key}\t$ac_hash3{$key}\tBacteria\n");	
				$count_b++;		
			}elsif ($archaea_acc{$ac_hash{$key}}) {
				print ($out5 "$key\tNA\t$ac_hash{$key}\t0\t$nonmetazoan_bitscore{$key}\t$ac_hash3{$key}\tArchea\n");	
				$count_a++;		
					
			}elsif ($fungi_acc{$ac_hash{$key}}) {
				print ($out5 "$key\tNA\t$ac_hash{$key}\t0\t$nonmetazoan_bitscore{$key}\t$ac_hash3{$key}\tFungi\n");	
				$count_f++;		
					
			}elsif ($plant_acc{$ac_hash{$key}}) {
				print ($out5 "$key\tNA\t$ac_hash{$key}\t0\t$nonmetazoan_bitscore{$key}\t$ac_hash3{$key}\tPlant\n");	
				$count_p++;		
					
			}elsif ($othereuk_acc{$ac_hash{$key}}) {
				print ($out5 "$key\tNA\t$ac_hash{$key}\t0\t$nonmetazoan_bitscore{$key}\t$ac_hash3{$key}\tOther Eukarote\n");	
				$count_e++;		
					
			}else{
				print ($out5 "$key\tNA\t$ac_hash{$key}\t0\t$nonmetazoan_bitscore{$key}\t$ac_hash3{$key}\tVirus\n");	
				$count_v++;			
			}
			$count++;
			$count2++;
		}else{
			print ($out5 "$key\tNA\t$ac_hash{$key}\tNA\t$nonmetazoan_bitscore{$key}\t$ac_hash3{$key}\tNA\n");			
		}		
	}
}

$p1 = 100 * ($count/$total);
$p2 = 100 * ($count2/$count);


print("Total transcripts with a hit: $total\nThere were $count HGT genes/transcripts ($p1 %)\n$count_b Bacteria\n$count_a Archaea\n$count_f Fungi\n$count_p Plant\n$count_e Other Eukarote\n$count_v Virus\n$count2 of them had no metazoan hit ($p2 %)\n");
