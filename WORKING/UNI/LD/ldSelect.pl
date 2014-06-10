#!/usr/local/bin/perl -w
use strict;

########################General Information For LD-Select#####################################
# LDSelect analyses the patterns of linkage disequilibrium between polymorphic sites         #
# in a locus, and bins the SNPs on the basis of a threshold level of LD as measured          #
# by r^2.                                                                                    #
#                                                                                            #
# At each round, the binning algorithm identifies the single SNP which exceeds threshold     #
# r^2 with the maximum number of other SNPs, and sets this set of SNPs as a bin.  Then       #
# each SNP within the bin is analyzed to determine whether it exceeds threshold r^2 with     #
# all other SNPs in the bin.  All SNPs in a bin that meet this criterion are designated as   #
# TagSNPs.  Only one TagSNP needs to be typed per bin.                                       #
#                                                                                            #
# The sequence context for each SNP is indicated by a two letter code preceeding the         #
# SNP reference sequence position.  The first position of the code indicates whether         #
# the sequence context is: (U)nique sequence or (R)epeat containing sequence.  This          #
# information is important because design genotyping assays is generally easier for unique   #
# sequences.                                                                                 #
#                                                                                            #
# The second position in the code provides information on the genomic context:               #
# (F)lanking region, 5' or 3' U(T)R, (I)ntron, (S)ynonymous cSNP, or (N)onsynonymous cSNP.   #
# (D)frame-shift, (X)unkown classifier.                                                      #
#                                                                                            #
# Version 1.13, programmed by Qian Yi. The software is provided "AS IS".                      #  
##############################################################################################
#constant to define the genotypes
my $HMZC = 1;
my $HMZR = 2;
my $HETER = 3;
my $UNKNOWN = 4;
my $CONFLICT = 5;

my %samples = ();
my %allele_for_site = ();
my %commonAllele = ();
my %minorAlleleFreq = ();
my %triAllelicSnps = ();
# hash of array to store a genotype ector for each site.
my %genotypeVec = ();
# r-squared is the pair-wised LD value
my %r2 = ();
my %snpContext = ();

my %ldSelectedBins = ();
my %tagSnps = ();
my @preSelectedSites = ();
my %excludedSites = ();
my %selectedSites = ();
my @sitesToBin = ();
my @triAllelicSites = ();
my %avgMinorAlleleFreqForBins = ();
my %missingGenotypeCount = ();
my %genotypeCoverage = ();

my %arg = ();
&parseCommandLine();
if ($arg{-sample}) {
	&getSamples();
}
&parsePrettybaseFile();
&calculateLD();
@triAllelicSites = keys(%triAllelicSnps);
@sitesToBin = keys(%r2);

if ($arg{-excluded}) {
	&getExcludedSites();
}

if (@triAllelicSites > 0) {
	&ldSelect(\@triAllelicSites);
}

if ($arg{-required}) {
	&getPreSelectedSites();
	&ldSelect(\@preSelectedSites);
}

&ldSelect(\@sitesToBin);
&calculateAvgMinorAlleleFreqForBins();
&outputBinsAndTagSnps();
exit;

sub parseCommandLine {
    my ( $usage ) = "ldSelect.pl\n";
	$usage .= "\t[-pb]\t\tprettybase file\n";

    # default values
    $arg{-pb} = '';
	$arg{-required} = '';
	$arg{-excluded} = '';
	$arg{-r2} = 0.64;
	$arg{-context} = '';
	$arg{-freq} = '';	
	$arg{-sample} = '';
	$arg{-gtPercentTagSnp} = 0;
	$arg{-gtPercentCluster} = 0;
        $arg{-verbose} = '';

	my $arg;
    foreach $arg (sort keys %arg) {
        next if ( $arg eq "-pb" );
		if ( $arg eq "-r2" ) {
			$usage .= "\t<$arg>\t\tr-squared threshold (0.0 - 1.0; default = 0.64)\n";
		}
		if ( $arg eq "-freq" ) {
			$usage .= "\t<$arg>\t\tminor allele frequency threshold (> 0.0 and <= 0.5)\n";
		}
		if ( $arg eq "-sample" ) {
			$usage .= "\t<$arg>\ta list of samples to be clustered\n";
		}
		if ( $arg eq "-required" ) {
			$usage .= "\t<$arg>\ta list of sites required to be tagSNPs\n";
		}
		if ( $arg eq "-excluded" ) {
			$usage .= "\t<$arg>\ta list of sites that can not be tagSNPs\n";
		}
		if ($arg eq "-context" ) {
			$usage .= "\t<$arg>\ta file containing genomic and sequence context for snps\n";
		}
		if ($arg eq "-gtPercentTagSnp" ) {
			$usage .= "\t<$arg>\tminimal genotype coverage in percent (0 - 100, default = 0) for a snp to be a potential TagSnp\n";
		}
		if ($arg eq "-gtPercentCluster" ) {
			$usage .= "\t<$arg>\tminimal genotype coverage in percent (0 - 100, default = 0) for a snp to be a potentially clutered with other snps\n";
		}
		if ($arg eq "-verbose" ) {
			$usage .= "\t<$arg>\tprint command line args? (y or n; default is 'no')\n";
		}
    }
    
# parse the command line
	my $i;
    for ( $i = 0; $i <= $#ARGV; $i++ ) {
        if ( $ARGV[$i] =~ /^-/ ) {
            $arg{$ARGV[$i]} = $ARGV[$i+1];
        }
    }

# required input args 
    die ( $usage ) if ( ! $arg{-pb} );
	die ( $usage ) if ( ! $arg{-r2} );

    $arg{-verbose} = uc($arg{-verbose});

    if ($arg{-verbose})
    {
	if ($arg{-verbose} ne 'N' && $arg{-verbose} ne 'Y' &&
	    $arg{-verbose} ne '0' && $arg{-verbose} ne '1')
	{
	    die "\nERROR: -verbose argument must be 'y' or 'n'\n\n$usage";
	}
    }

    if ($arg{-verbose} eq 'Y' || $arg{-verbose} eq '1')
    {
	print "ldSelect.pl run with command line arguments:\n";

	while (my ($k,$v) = each %arg)
	{
	    printf "  %15s  ", $k;
	    print "$v\n";
	}

	print "\n";
    }
}

sub getSamples{
	my ($line, $sample);

	open(SAMPLE, "$arg{-sample}") or die "Can't open $arg{-sample}\n";
	while ($line = <SAMPLE>) {
		next if ($line eq "\n");
		chomp($line);
		$sample = (split(" ", $line))[0];
		$samples{$sample} = 1;
	}
	close(SAMPLE);
}

sub parsePrettybaseFile {
	my $line;
	my ($site, $sample, $allele1, $allele2, $allele);
	my %genotype = ();
	my @alleles = ();
	my %firstHomoAllele = ();
	my $previousSite = '';

	open ( PBFILE, "$arg{-pb}" ) or die "Can't open $arg{-pb} file\n";
	while ( $line = <PBFILE> ) {
		next if ( $line eq "\n" );

		($site, $sample, $allele1, $allele2) = split ( " ", $line );
		next if ($arg{-sample} && !exists($samples{$sample}));
		# force to drop the padding zeros in front of site
		$site = $site - 0;
		$genotype{$site}{$sample} = "$allele1\t$allele2";

		# initialize missing genotype count
		if (!exists($missingGenotypeCount{$site})) {
			$missingGenotypeCount{$site} = 0;
		}		

		# to store the allele of the first homozygous genotype, that will be
		# the common allele in case of 50:50 alllele counts.
		if (($previousSite ne $site) && ("\U$allele1" eq "\U$allele2") && 
			!exists($firstHomoAllele{$site})) {
			$firstHomoAllele{$site} = "\U$allele1";
			$previousSite = $site;
		}
			
		#skip all the conflicts and NN's before we count the alleles
		#next if ( "\U$allele1" eq "X" || "\U$allele2" eq "X");
		#next if ( "\U$allele1" eq "N" || "\U$allele2" eq "N");
		if ("\U$allele1" eq "X" || "\U$allele1" eq "N") {
			$missingGenotypeCount{$site}++;
		}
		else {
			($allele_for_site{$site}{"\U$allele1"})++;
		}
		if ("\U$allele2" eq "X" || "\U$allele2" eq "N") {
			$missingGenotypeCount{$site}++;
		}
		else {
			($allele_for_site{$site}{"\U$allele2"})++;
		}

	}
	close(PBFILE);

	#find the common allele, and tri-allele-snps
	my $tmpCount = 0;
	foreach $site (keys(%allele_for_site)) {
		#print "$site\t";
		# find tri-allelic snp
		@alleles = keys(%{$allele_for_site{$site}});
		if (@alleles > 2) {
			$triAllelicSnps{$site} = 1;
		}
		#find common allele
		$tmpCount = 0;
		foreach $allele (@alleles) {
			if ($allele_for_site{$site}{$allele} > $tmpCount) {
				$commonAllele{$site} = $allele;
				$tmpCount = $allele_for_site{$site}{$allele};
			}
			elsif ($allele_for_site{$site}{$allele} == $tmpCount) {
				if ($allele eq $firstHomoAllele{$site}) {
					$commonAllele{$site} = $allele;
				}
			}
		}
		#print "$commonAllele{$site}\n";
	}

	&calculateMinorAlleleFreq();

	#build up the genotype vector for each site.
	foreach $site (keys(%genotype)) {
		next if ( $arg{-freq} && ($minorAlleleFreq{$site} < $arg{-freq}) );

		foreach $sample (sort(keys(%{$genotype{$site}}))) {
			($allele1, $allele2) = split(/\t/, $genotype{$site}{$sample});
			if ("\U$allele1" ne "\U$allele2") {
				push(@{$genotypeVec{$site}}, $HETER);
			}
			else {
				if ("\U$allele1" eq "N") {
					push(@{$genotypeVec{$site}}, $UNKNOWN);
				}
				elsif ("\U$allele1" eq "X") {
					push(@{$genotypeVec{$site}}, $CONFLICT);
				}
				elsif ("\U$allele1" eq $commonAllele{$site}) {
					push(@{$genotypeVec{$site}}, $HMZC);
				}
				else {
					push(@{$genotypeVec{$site}}, $HMZR);
				}
			}
		}
	}

	#DEBUG
	#foreach $site (sort (keys(%genotypeVec)) ) {
	#	print "$site\t";
	#	print @{$genotypeVec{$site}};
	#	print "\n";
	#}
}

sub calculateMinorAlleleFreq {
	my ($site, $allele);
	my %total_allele = ();
	my @all_alleles = ();

	#calculate total allele count excluding NN's
	foreach $site ( keys %allele_for_site ) {
		$total_allele{$site} = 0;
		foreach $allele ( keys(%{$allele_for_site{$site}}) ) {
			next if ($allele eq "N");

			$total_allele{$site} += $allele_for_site{$site}{$allele};
		}
	}
					
	#calculate the major allele freq. and NN percentage
	foreach $site (sort keys %allele_for_site ) {
		# calculate the major allele frequency
		if ($total_allele{$site} != 0) {
			$minorAlleleFreq{$site}
		 	= 1- ($allele_for_site{$site}{$commonAllele{$site}} / $total_allele{$site});

			# ---> FOR DEBUGGING <---
			#if ($minorAlleleFreq{$site} > .09 && $minorAlleleFreq{$site} < .11)
			#{
			#    printf("%.51f\n", $minorAlleleFreq{$site});
			#}

			# this line is important - sometimes the computer will store the MAF as
			# something other than what you expect (e.g., 0.009999999999735... instead
			# of 0.10), which can lead to problems with boundary cases later on
			$minorAlleleFreq{$site} = sprintf("%.6f", $minorAlleleFreq{$site});

			$genotypeCoverage{$site} =  100 * $total_allele{$site}/($total_allele{$site} + $missingGenotypeCount{$site});
		}
		else {
			die "Something is wrong, the total number of samples is 0.\n";
		}
	}			
}

sub calculateLD {
	my @sites = sort(keys(%genotypeVec));
	my @vector1 = ();
	my @vector2 = ();

	my $genotype1 = 0;
	my $genotype2 = 0;
	my $i = 0;
	my $j = 0;
	my $k = 0;
	for ($i = 0; $i < @sites; $i++) {
		$r2{$sites[$i]}{$sites[$i]} = 1;
		@vector1 = @{$genotypeVec{$sites[$i]}};
		for($j = $i+1; $j < @sites; $j++) {
			@vector2 = @{$genotypeVec{$sites[$j]}};

			if (@vector1 != @vector2) {
				die "Something is wrong with the prettybase input\n";
			}

			my $a1a1b1b1 = 0;
			my $a1a1b2b2 = 0;
			my $a1a1b1b2 = 0;
			my $a2a2b1b1 = 0;
			my $a2a2b2b2 = 0;
			my $a2a2b1b2 = 0;
			my $a1a2b1b1 = 0;
			my $a1a2b2b2 = 0;
			my $a1a2b1b2 = 0;
			for ($k = 0; $k < @vector1; $k++) {
				$genotype1 = $vector1[$k];
				$genotype2 = $vector2[$k];

				if ($genotype1 == 1) {
					if ($genotype2 == 1) {
						$a1a1b1b1++;
						# some3By3[0][0]++;
					}
					elsif ($genotype2 == 2) {
						$a1a1b2b2++;
						# some3By3[2][0]++;
					}
					elsif ($genotype2 == 3) {
						$a1a1b1b2++;
						# some3By3[1][0]++;
					}
				}
				elsif ($genotype1 == 2) {
					if ($genotype2 == 1) {
						$a2a2b1b1++;
						# some3By3[0][2]++;
					}
					elsif ($genotype2 == 2) {
						$a2a2b2b2++;
						# some3By3[2][2]++;
					}
					elsif ($genotype2 == 3) {
						$a2a2b1b2++;
						# some3By3[1][2]++;
					}
				}
				elsif ($genotype1 == 3) {
					if ($genotype2 == 1) {
						$a1a2b1b1++;
						# some3By3[0][1]++;
					}
					elsif ($genotype2 == 2) {
						$a1a2b2b2++;
						# some3By3[2][1]++;
					}
					elsif ($genotype2 == 3) {
						$a1a2b1b2++;
						# some3By3[1][1]++;
					}
				}
			}

			my $n = $a1a1b1b1 + $a1a1b1b2 + $a1a1b2b2 +
			        $a1a2b1b1 + $a1a2b1b2 + $a1a2b2b2 +
			        $a2a2b1b1 + $a2a2b1b2 + $a2a2b2b2; 

			my $x11 = 2*$a1a1b1b1 + $a1a1b1b2 + $a1a2b1b1;
			my $x12 = 2*$a1a1b2b2 + $a1a1b1b2 + $a1a2b2b2;
			my $x21 = 2*$a2a2b1b1 + $a1a2b1b1 + $a2a2b1b2;
			my $x22 = 2*$a2a2b2b2 + $a1a2b2b2 + $a2a2b1b2;

			my $p = ($x11 + $x12 + $a1a2b1b2) / (2*$n);
			my $q = ($x11 + $x21 + $a1a2b1b2) / (2*$n);

			my $p11 = $p * $q;

			my $convergentCounter = 0;
			my $oldP11 = $p11;
			my $range = 0.0;
			my $converged = "false";
			if ($p11 > 0) {
				while ($converged eq "false" && $convergentCounter < 100) {
					if ((1.0 - $p - $q + $p11) != 0.0 && $oldP11 != 0.0) {
						$p11 = ($x11 + (($a1a2b1b2 * $p11 * (1.0 - $p - $q + $p11))/($p11 * (1.0 - $p - $q + $p11) + ($p - $p11)*($q - $p11))))/(2.0*$n);
						$range = $p11/$oldP11;
						if (($range >= 0.9999) && ($range <= 1.001)) {
							$converged = "true";
						}
						$oldP11 = $p11;
						$convergentCounter++;
					}
					else {
						#$p11 = $p * $q;
						$converged = "true";
					}
				}
			}

			# calculate D
			my $dValue = 0.0;
			if ($converged eq "true") {
				$dValue = $p11 - ($p * $q);
			}

			#calculate r2
			if ($dValue != 0.0) {
				$r2{$sites[$i]}{$sites[$j]} = ($dValue**2) / ($p * $q * (1 - $p) * (1 - $q));
			}
			else {
				$r2{$sites[$i]}{$sites[$j]} = 0;
			}
		}
	}

	#DEBUG
	#for($i = 0; $i < @sites; $i++) {
	#	print "$sites[$i]\t";
	#	printf("%0.2f\t", $r2{$sites[$i]}{$sites[$i]});
	#	for ($j = $i+1; $j < @sites; $j++) {
	#		printf("%0.2f\t", $r2{$sites[$i]}{$sites[$j]});
	#	}
	#	print "\n";
	#}

}

sub ldSelect {
	my ($targetedSitesToBin_ref) = @_;

	my @targetedSitesToBin = @{$targetedSitesToBin_ref};
	my $k = 0;
	my $i = 0;
	my $j = 0;
	my $r2Value = 0;

	for ($k = 0; $k < @targetedSitesToBin; $k++) {

		my @biggestBin = ();
		if (exists($triAllelicSnps{$targetedSitesToBin[$k]})) {
			@biggestBin = ($targetedSitesToBin[$k]);
		}
		else {
			for ($i = 0; $i < @targetedSitesToBin; $i++) {
				next if (exists($excludedSites{$targetedSitesToBin[$i]}));
				next if (exists($selectedSites{$targetedSitesToBin[$i]}));
				next if ($genotypeCoverage{$targetedSitesToBin[$i]} < $arg{-gtPercentTagSnp});

				my @tmpBin = ();
				for ($j = 0; $j < @sitesToBin; $j++) {
					# because only half of the matrix of pairwised value are calculated
					if (exists($r2{$targetedSitesToBin[$i]}{$sitesToBin[$j]})) {
						$r2Value = $r2{$targetedSitesToBin[$i]}{$sitesToBin[$j]};
					}
					elsif (exists($r2{$sitesToBin[$j]}{$targetedSitesToBin[$i]})) {
						$r2Value = $r2{$sitesToBin[$j]}{$targetedSitesToBin[$i]};
					}
					else {
						die "something may be wrong with your snp site $targetedSitesToBin[$i] that may not exist in the prettybase\n";
					}

					if (($r2Value >= $arg{-r2}) && !exists($selectedSites{$sitesToBin[$j]}) &&
						($genotypeCoverage{$sitesToBin[$j]} >= $arg{-gtPercentCluster}) ) {
						push(@tmpBin, $sitesToBin[$j]);
					}
				}

				if (@tmpBin > @biggestBin) {
					@biggestBin = ( @tmpBin ) ;
				}
			}
		}

		#next if (@biggestBin == 0);
		if (@biggestBin > 0) {
			# to keep track of which sites are selected already
			foreach my $site (@biggestBin) {
				$selectedSites{$site} = 1;
				#$sitesTaken++;
			}

			# keep track of selected bins	
			@{$ldSelectedBins{$biggestBin[0]}} = ( sort(@biggestBin) );

			# find tagSNPs for each selected bin
			my $canBeTagSnp = "true";
			for ($i = 0; $i < @biggestBin; $i++) {
				if (exists($excludedSites{$biggestBin[$i]}) || 
					$genotypeCoverage{$biggestBin[$i]} < $arg{-gtPercentTagSnp}) {
					$canBeTagSnp = "false";
				}
				else {
					for ($j = 0; $j < @biggestBin; $j++) {
						next if ($i == $j);

						if (exists($r2{$biggestBin[$i]}{$biggestBin[$j]})) {
							$r2Value = $r2{$biggestBin[$i]}{$biggestBin[$j]};
						}
						else {
							$r2Value = $r2{$biggestBin[$j]}{$biggestBin[$i]};
						}
		
						if ($r2Value < $arg{-r2}) {
							$canBeTagSnp = "false";
							last;
						}
					}
				}

				#keep track of the tagSnps
				if ($canBeTagSnp eq "true") {
					$tagSnps{$biggestBin[$i]} = 1;
				}

				# reset $canBeTagSnp for next site
				$canBeTagSnp = "true";
			}
		}
		else { # if the biggest bin comes out empty, stop clustering
			last;
		}
	}
	# In the end , some snps may not be clustered because the cutoffs of -gtPercentTagSnp
	#  and -gtPercentCluster. So,  put each of those snps into a bin by itself.
	if (@targetedSitesToBin == @sitesToBin) {
		for ($k = 0; $k < @targetedSitesToBin; $k++) {
			next if ( exists($selectedSites{$targetedSitesToBin[$k]}) );

			# keep track of selected bins	
			@{$ldSelectedBins{$targetedSitesToBin[$k]}} = ( $targetedSitesToBin[$k] );	
			$tagSnps{$targetedSitesToBin[$k]} = 1;
			$selectedSites{$targetedSitesToBin[$k]} = 1;
		}
	}
}

sub calculateAvgMinorAlleleFreqForBins {
	my ($i, $totalSites, $sumFreqs, $avgFreq);

	my @bins = keys(%ldSelectedBins);

	for ($i = $#bins; $i >=0; $i--) {
		$totalSites = 0;
		$sumFreqs = 0.0;
		$avgFreq = 0.0;
		my $site;
		foreach $site (@{$ldSelectedBins{$bins[$i]}}) {
			$totalSites++;
			if (exists($minorAlleleFreq{$site})) {
				$sumFreqs += $minorAlleleFreq{$site};
			}
			else {
				die "Something is wrong, no minor alllele freq. for site $site\n";
			}
		}

		if ($totalSites != 0) {
			$avgFreq = $sumFreqs/$totalSites * 100;
			$avgMinorAlleleFreqForBins{$bins[$i]} = $avgFreq;
		}
		else {
			die "Something is wrong because total # of sites in this bin is 0\n";
		}
	}
}
		
sub outputBinsAndTagSnps {
	my ($site, $bin);
	my $totalSites = 0;
	my $index_first_nonsinglton_bin = 0;
	my @singletonBins = ();
	my @sortedSingletonBins = ();
	my @finalSortedBins = ();
	my @tmpBins = ();
	my @sortedTmpBins = ();

	my @bins = sort { @{$ldSelectedBins{$a}} <=> @{$ldSelectedBins{$b}} } (keys(%ldSelectedBins));

	# Debbie wants the singlton bins to be sorted by mimor allele frequency.
	my $i;
	for ($i = 0; $i < @bins; $i++) {
		if ( $totalSites != @{$ldSelectedBins{$bins[$i]}} ) {
			if (@tmpBins != 0) {
				@sortedTmpBins = sort { $avgMinorAlleleFreqForBins{$a} <=> $avgMinorAlleleFreqForBins{$b} } (@tmpBins);	
				push(@finalSortedBins, 	@sortedTmpBins);
			}
			@tmpBins = ();
			@sortedTmpBins = ();
			$totalSites = @{$ldSelectedBins{$bins[$i]}};
		}
		push(@tmpBins, $bins[$i]);
	}
	@sortedTmpBins = sort { $avgMinorAlleleFreqForBins{$a} <=> $avgMinorAlleleFreqForBins{$b} } (@tmpBins);	
	push(@finalSortedBins, 	@sortedTmpBins);

	if ($arg{-context}) {
		&getSnpContext();
	}

	for ($i = $#finalSortedBins; $i >=0; $i--) {
		$totalSites = @{$ldSelectedBins{$finalSortedBins[$i]}};
		#output info for each bin
		printf("Bin %d\t", @finalSortedBins - $i);
		print "total_sites: $totalSites\t";
		printf("average_minor_allele_frequency: %.0f", $avgMinorAlleleFreqForBins{$finalSortedBins[$i]});
		print "%\n";
		printf("Bin %d\t", @finalSortedBins - $i);
		print "TagSnps: ";
		foreach $site (sort {$a <=> $b} @{$ldSelectedBins{$finalSortedBins[$i]}}) {	
			if (exists($tagSnps{$site})) {
				if (exists($snpContext{$site})) {
					print $snpContext{$site}->{"Sequence"};
					print $snpContext{$site}->{"Genomic"};
					print "-";
				}
				print "$site ";
			}
		}
		print "\n";
		printf("Bin %d\t", @finalSortedBins - $i);
		print "other_snps: ";
		foreach $site (sort {$a <=> $b} @{$ldSelectedBins{$finalSortedBins[$i]}}) {	
			if (!exists($tagSnps{$site})) {
				if (exists($snpContext{$site})) {
					print $snpContext{$site}->{"Sequence"};
					print $snpContext{$site}->{"Genomic"};
					print "-";
				}
				if (exists($excludedSites{$site})) {
					print "($site) ";
				}
				else {
					print "$site ";
				}
			}
		}
		print "\n\n";			
	}
}

sub getPreSelectedSites {
	my ($line, $site);

	open(IN, "$arg{-required}") or die "Can't open file $arg{-required}\n";
	while ($line = <IN> ) {
		next if ($line eq "\n");

		$site = (split(" ", $line))[0];
		push(@preSelectedSites, $site);
	}
	close(IN);
}

sub getExcludedSites {
	my ($line, $site);

	open(IN, "$arg{-excluded}") or die "Can't open file $arg{-excluded}\n";
	while ($line = <IN> ) {
		next if ($line eq "\n");

		$site = (split(" ", $line))[0];
		$excludedSites{$site} = 1;
	}
	close(IN);
}

sub getSnpContext {
	my ($site, $line);
	my ($genomicContext, $seqContext);

	open(INPUT, "$arg{-context}") or die "Can't open file $arg{-context}\n";
	while ($line = <INPUT>) {
		($site, $genomicContext, $seqContext) = split(" ", $line);
		if ($genomicContext =~ /flanking|Flanking/) {
			$genomicContext = 'F';
		}
		elsif ($genomicContext =~ /utr|UTR/) {
			$genomicContext = 'U';
		}
		elsif ($genomicContext =~ /intron|Intron/) {
			$genomicContext = 'I';
		}
		elsif ($genomicContext =~ /nonsyn|Nonsyn/) {
			$genomicContext = 'N';
		}
		elsif ($genomicContext =~ /^synon|^Synon/) {
			$genomicContext = 'S';
		}
		elsif ($genomicContext =~ /frame-shift|Frame-Shift/) {
			$genomicContext = 'T';
		}
		else {
			$genomicContext = 'X';
		}

		if ($seqContext =~ /repeat|Repeat/) {
			$seqContext = 'R';
		}
		elsif ($seqContext =~ /unique|Unique/) {
			$seqContext = 'U';
		}
		else {
			$seqContext = 'X';
		}

		$snpContext{$site} = { "Genomic" => $genomicContext,
		                       "Sequence" => $seqContext };
	}
	close(INPUT);
}

