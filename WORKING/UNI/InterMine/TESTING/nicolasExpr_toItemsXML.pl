#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Std;

use feature ':5.12';

use BlastSynbio qw/run_BLAST/;
use SynbioGene2Location qw/geneLocation/;
use SynbioRegionSearch qw/regionSearch/;

use InterMine::Item::Document;
use InterMine::Model;

# Print unicode to standard out
binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

my $usage = "usage: $0 nicolas_expression_tab IM_model_file.xml

\n";

### command line options ###
my (%opts, $debug);

getopts('hd', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"d"} and $debug++;

unless ( $ARGV[1] ) { die $usage };

my ($expr_file, $model_file) = @ARGV;

# synonyms file downloaded from bacilluscope: ids, symbols and synonyms extracted
my $synonyms_file = "/home/ml590/MIKE/InterMine/SynBioMine/DataSources/bsub_id_symbol_synonyms_May2014.txt";

open(SYN_FILE, "< $synonyms_file") || die "cannot open $synonyms_file: $!\n";

# process id, symbol, synonyms file
my %id2synonym; # hash lookup for symbols/ synonyms

while (<SYN_FILE>) {
  chomp;
  my ($identifier, $symbol, $syn_line) = split("\t", $_);
  $id2synonym{$symbol} = [$identifier] if $symbol; # use array ref as some symbols are not unique

  my @synonyms;
  if ($syn_line) {
    if ($syn_line =~ m/, /) {
      @synonyms = split(", ", $syn_line);
    } else {
      if ( exists $id2synonym{$syn_line} ) {
	say "DUPLICATE: $syn_line $identifier" if ($debug);
	push(@{ $id2synonym{$syn_line} }, $identifier);
      } else {
	$id2synonym{$syn_line} = [$identifier];
      }
    }
  }

  foreach my $synonym (@synonyms) {
    if ( exists $id2synonym{$synonym} ) {
      say "DUPLICATE: $synonym $identifier" if ($debug);
      push(@{ $id2synonym{$synonym} }, $identifier);
    } else {
      $id2synonym{$synonym} = [$identifier];
    }
  }
}
close SYN_FILE;

if ($debug) {
  foreach my $key (keys %id2synonym) {
    say $key, " : ", join("; ", @{ $id2synonym{$key} });
  }
}

open(EXP_FILE, "< $expr_file") || die "cannot open $expr_file: $!\n";

chomp (my @matrix = <EXP_FILE>);
close (EXP_FILE);
#my $info = shift(@matrix);
my $headers = shift(@matrix); # extract headers

my ($id_h, $strand_h, $posV3_h, $posV3min_h, $posV3max_h, 
  + $multdbtbs_h, $comp_h, $sig_h, $pcomp_h, $psig_h, 
  + $xcortree_h, $SigmaFactorBS_h, $chipUnb_h, $chipMnb_h, 
  + $clcortreeUC_h, $clcortreeUB_h, $clcortreeUA_h, $VarExp_h, 
  + $VarExpPropUnexpl_h, $beginTU_h, $endTUshort_h, $endTUlong_h, 
  + $listShort_h, $listLong_h)  = split("\t", $headers);

my $taxon_id = "224308";
my $title = "Promoters - The condition-dependent transcriptome of Bacillus subtilis 168";
my $pmid = "22383849";
my $accession = "GSE27219";
my $seq_length = 101;

my $chromosome = "NC_000964.3";
my $work_dir = "/home/ml590/MIKE/InterMine/SynBioMine/DataSources/BLAST/Bsub168";

my $model = new InterMine::Model(file => $model_file);
my $doc = new InterMine::Item::Document(model => $model);

my $org_item = make_item(
    Organism => (
        taxonId => $taxon_id,
    )
);

my $data_source_item = make_item(
    DataSource => (
        name => $title,
    ),
);

my $publication_item = make_item(
    Publication => (
        pubMedId => $pmid,
    ),
);

my $evidence_item = &make_item(
    PromoterEvidence => (
	publications => [ $publication_item ],
    ),
);

my $data_set_item = make_item(
    DataSet => (
        name => "Promoters ($accession) for taxon id: $taxon_id",
	publication => $publication_item,
	dataSource => $data_source_item,
    ),
);

my $chromosome_item = make_item(
    Chromosome => (
        primaryIdentifier => $chromosome,
    ),
);

my %seen_genes; # store genes that have been resolved to unique identifiers
my %seen_gene_items; # track processed gene items
my %seen_pred_sigma_items; # track processed predicted sigma items
my %seen_sigma_BF_items; # track processed sigma binding factor items

for my $entry (@matrix)
{
#  chomp $entry;
  my ($id, $strand, $posV3, $posV3min, $posV3max, $multdbtbs, 
  + $comp, $sig, $pcomp, $psig, $xcortree, $SigmaFactorBS, $chipUnb, 
  + $chipMnb, $clcortreeUC, $clcortreeUB, $clcortreeUA, $VarExp, 
  + $VarExpPropUnexpl, $beginTU, $endTUshort, $endTUlong, $listShort, $listLong) = split("\t", $entry);

  $id = uc($id);

# BLAST seqs and process blast results
  my ($regionRef);
  if ($SigmaFactorBS) {
    my $query = ">$id\n$SigmaFactorBS";
    $regionRef = &run_BLAST($query, $seq_length, $work_dir, $debug);
  }

  my @prom_regions = @{ $regionRef } if ($regionRef);

# If we have a region - check that it has a unique location
  my $region;
  if ( scalar(@prom_regions) > 1) {
    warn "Sequence is not unique: $SigmaFactorBS\n";
    next;
  } else {
    $region = $prom_regions[0];
  }

# turn the region string back into its sub-parts - seems a bit clunky but hey...
  $region =~ m/(.+)\:(.+)\.\.(.+) (.+)/; 
  my ($chr, $start_found, $end_found, $strand_found) = ($1, $2, $3, $4) if ($region);


  if ($start_found) {

# process predicted Sigma Factors and split any that have multi-assignments
    my $pred_sig_factor = ($sig !~ m/Sig-/) ? $sig : undef;

    my ($prefix, $chars, @chars, @pred_sig_factors);
    if ($pred_sig_factor) {
      if ($pred_sig_factor =~ /^(Sig)([A-Z]+)/) { 
# split multipart identifier eg SigABC into Sig ABC
	$prefix = $1;
	$chars = $2;
	@chars = split(//, $chars); # split ABC part
	@pred_sig_factors = map { "Sig$_" } @chars; # add 'Sig' prefix to each eg. SigA
      } else {
	push (@pred_sig_factors, $pred_sig_factor); # if it's not multipart, add it to our array
      } 
    }

    my @genes = split(", ", $listShort);

    my ($gene_id, $promoter_id);
    for my $gene (@genes) {
      next if ($gene =~ /^S\d+/);
      next if ($gene =~ /^NA/);
      $gene_id = $gene;
      last;
    }
  
    next unless $gene_id;
    say "Working on symbol: $gene_id" if ($debug);

    my $geneDBidentifier = &resolver($gene_id, $region);
    next unless ($geneDBidentifier); # skip if we can't get a unique ID
    $promoter_id = $id . "_" . $gene_id . "_" . $geneDBidentifier . "_" . $taxon_id;

  ############################################
  # Set info for gene - first, check if we've seen it before
    my $gene_item = &gene_item($geneDBidentifier);

    my ($sigmaDBidentifier, $pred_sig_item, @pred_sig_items);
    for my $factor (@pred_sig_factors) {
      my $factor_id = lcfirst($factor);
      $sigmaDBidentifier = &resolver($factor_id, undef);
      next unless ($sigmaDBidentifier);
      
      my $pred_sig_gene_item = &gene_item($sigmaDBidentifier) if ($sigmaDBidentifier);
      say "PredSig: $sigmaDBidentifier has $pred_sig_gene_item with $psig" if  ($debug);

      if (exists $seen_pred_sigma_items{$sigmaDBidentifier}) {
	$pred_sig_item = $seen_pred_sigma_items{$sigmaDBidentifier};
	
      } else {
# make predicted sigma factor items
	$pred_sig_item = make_item(
	  PredictedSigmaFactor => (
	    primaryIdentifier => $pred_sig_gene_item,
	    probability => $psig,
	  ),
	);
	$seen_pred_sigma_items{$sigmaDBidentifier} = $pred_sig_item;
      }
      push (@pred_sig_items, $pred_sig_item); # array of predicted sigma factor items

    }

# process predicted Sigma Factor Binding sites and split any that have multi-assignments
    my $sig_BF = ($multdbtbs !~ m/-/) ? $multdbtbs : undef;

    my (@sig_BFs, $sigmaBF_DBidentifier, $sigBF_gene_item, $sig_BF_item, @sig_BF_items);
    if ($sig_BF) {
      if ($sig_BF =~ m/,/) {
	@sig_BFs = split(/,/, $sig_BF);
      } else {
	push (@sig_BFs, $sig_BF);
      }

      for my $b_factor (@sig_BFs) {
	my $b_factor_id = lcfirst($b_factor);
	$sigmaBF_DBidentifier = &resolver($b_factor_id, undef);
	next unless ($sigmaBF_DBidentifier);

	my $sigBF_gene_item = &gene_item($sigmaBF_DBidentifier) if ($sigmaBF_DBidentifier);
	say "SigBF: $sigmaBF_DBidentifier has $sigBF_gene_item" if ($debug);

	if (exists $seen_sigma_BF_items{$sigmaBF_DBidentifier}) {
	  $sig_BF_item = $seen_sigma_BF_items{$sigmaBF_DBidentifier};
	  
	} else {
  # make predicted sigma factor items
	  $sig_BF_item = &make_item(
	    SigmaBindingFactor => (
	      primaryIdentifier => $sigBF_gene_item,
	    ),
	  );
	  $seen_sigma_BF_items{$sigmaBF_DBidentifier} = $sig_BF_item;
	}
	push (@sig_BF_items, $sig_BF_item); # array of sigma bf items
      }
    }


  ############################################
  # Set info for sequence 
    my $seq_item = make_item(
	Sequence => (
	    'length' => $seq_length,
	    residues => $SigmaFactorBS,
	),
    );

    my $location_item = make_item(
	Location => (
	    start => $start_found,
	    end => $end_found,
	    strand => $strand_found,
	    dataSets => [$data_set_item],
	),
    );

# 	  predictedSigmaFactor => $pred_sig_factor,
   my $promoter_item = make_item(
       Promoter => (
	  primaryIdentifier => $promoter_id,
	  gene => $seen_gene_items{$geneDBidentifier},
	  predictedCluster => $comp,
	  clusterProbability => $pcomp,
	  chromosome => $chromosome_item,
	  chromosomeLocation => $location_item,
	  sequence => $seq_item,
	  evidence => [$evidence_item],
	  dataSets => [$data_set_item],
       ),
   );

  if ($debug) {
    say "Promoter:
	  primaryIdentifier: $promoter_id,
	  gene: $seen_gene_items{$geneDBidentifier},
	  predictedCluster: $comp,
	  clusterProbability: $pcomp,
	  chromosome: $chromosome_item,
	  chromosomeLocation: $location_item,
	  sequence: $seq_item,
	  evidence:$evidence_item,
	  dataSets: [$data_set_item]"
  }

# #    for (@sig_BF_items) {
# #     $_->{promoter} = $promoter_item;
# #    }
# #    for (@pred_sig_items) {
# #     $_->{promoter} = $promoter_item;
# #    }

  $promoter_item->set( predictedSigmaFactors => \@pred_sig_items ) if @pred_sig_items;
  $promoter_item->set( sigmaBindingFactors => \@sig_BF_items ) if @sig_BF_items;

############################################
###  Add completed promoter item to collection for genes, tfac etc
  push( @{ $seen_gene_items{$geneDBidentifier}->{'promoters'} }, $promoter_item ) if ($geneDBidentifier);
  push( @{ $seen_pred_sigma_items{$sigmaDBidentifier}->{'promoters'} }, $promoter_item ) if ($sigmaDBidentifier);
  push( @{ $seen_sigma_BF_items{$sigmaBF_DBidentifier}->{'promoters'} }, $promoter_item ) if ($sigmaBF_DBidentifier);

############################################

 }
}

$doc->close(); # writes the xml
exit(0);

####### MAIN SUBS #######

sub resolver {
  my ($symbol, $region) = @_;
  my $gene2check = lcfirst($symbol);

  my $geneLookupRef = &gene_lookup($gene2check, $region);
  my @geneDBids = @{ $geneLookupRef } if ($geneLookupRef);

  my $geneDBidentifier;
  if ($geneLookupRef) {
    for my $identifier (@geneDBids) {
      say "Success: $gene2check resolved to $identifier" if ($debug);
      $geneDBidentifier = $identifier;
      $seen_genes{$gene2check} = $identifier unless (exists $seen_genes{$gene2check});
    }
  } else {
    say "Fail: Nothing returned from gene lookup with: $gene2check" if ($debug);
    return;
  }
  
  return $geneDBidentifier;

}

sub gene_lookup {

  my ($gene_symbol, $region) = @_;

  my ($synbioRef, @identifiers);
  if ( exists $seen_genes{$gene_symbol} ) {
    say "Great! Already seen $gene_symbol. Reusing resolved ID..." if ($debug);
    push (@identifiers, $seen_genes{$gene_symbol});
    $synbioRef = \@identifiers;
    return $synbioRef;
  }

  my ($chromosome, $start, $end, $strand, $extend_coord, $extend_region);

  if ($region) {
    $region =~ m/(.+)\:(.+)\.\.(.+) (.+)/; 
    ($chromosome, $start, $end, $strand) = ($1, $2, $3, $4);

    if ($strand =~ m/-/) {
      $extend_coord = ($start - 200);
      $extend_region = "$chromosome:$extend_coord..$end";
    } else {
      $extend_coord = ($end + 200);
      $extend_region = "$chromosome:$start..$extend_coord";
    }
  }  

  if ( exists $id2synonym{$gene_symbol} ) {
    if (scalar( @{ $id2synonym{$gene_symbol} } > 1) ) {
      say "$gene_symbol is not unique: ", join("; ", @{ $id2synonym{$gene_symbol} }), "\n" if ($debug);

      if ($region) {
	say "Checking region ($extend_region) against SynBioMine..." if ($debug);

# call a module to query synbiomine regioSearch for gene id
	my ($org_short, $geneRef) = regionSearch($extend_region);
	my @genes_synbio = @$geneRef;

	foreach my $synbio_gene (@genes_synbio) {
	  my $symbol = $synbio_gene->[0];
	  my $identifier = $synbio_gene->[1];
	  push (@identifiers, $identifier);
	  say "Found: $gene_symbol matches S: $symbol\tID: $identifier" if ($debug);
	}

      } else {
	say "No region - searching SynBioMine by ID..." if ($debug);
	my $geneRef = $id2synonym{$gene_symbol};
	$synbioRef = &synbiomine_genes($gene_symbol, $geneRef, $region);
      }

    } else {
      say "Match: $gene_symbol matches: ", $id2synonym{$gene_symbol}->[0] if ($debug);
      my $match = $id2synonym{$gene_symbol}->[0];
      push (@identifiers, $match);
    }
  } else {
    say "Can't find $gene_symbol in lookup. Checking SynBioMine..." if ($debug);
    my $geneRef = [ $gene_symbol ];
    $synbioRef = &synbiomine_genes($gene_symbol, $geneRef, $region);
  }

  $synbioRef = \@identifiers if (@identifiers);
  return $synbioRef;

}

sub synbiomine_genes {

  my ($symbol2check, $gene2check, $region) = @_;
  my $org_short = "B. subtilis subsp. subtilis str. 168";

  my @identifiers;
  foreach my $id ( @{ $gene2check} ) {

    my ($geneRef) = geneLocation($org_short, $id);
    my @gene_lookups = @$geneRef;

    if (scalar(@gene_lookups) > 1 ) {
      say "Houston, we have an ambiguity problem: $id" if ($debug);
    } else {
      my $identifier = $gene_lookups[0]->[0];
      my $symbol = $gene_lookups[0]->[1];

      if ( ($symbol) && ($symbol eq $symbol2check) ) {
	say "Symbols match: $symbol eq $symbol2check - resolving to $identifier" if ($debug);
	push (@identifiers, $identifier);
	return \@identifiers;
      } 
      elsif ( ($symbol) && ($symbol ne $symbol2check) ) {
	say "Symbols don't match: $symbol eq $symbol2check - can't resolve $identifier" if ($debug);
#	push (@identifiers, $identifier);
      }
      else {
	say "$id not found in synbiomine!" if ($debug);
      }
    }
  }

  if (@identifiers) {
    \@identifiers;
  } else { return; }

}

######## helper subroutines:

sub gene_item {
  my $id = shift;

  my $gene_item;
  if (exists $seen_gene_items{$id}) {
    $gene_item = $seen_gene_items{$id};
  } else {
    $gene_item = make_item(
	Gene => (
	    primaryIdentifier => $id,
	),
    );

    $seen_gene_items{$id} = $gene_item;
  }
  return $gene_item;
}

sub make_item {
    my @args = @_;
    my $item = $doc->add_item(@args);
    if ($item->valid_field('organism')) {
        $item->set(organism => $org_item);
    }
    return $item;
}
