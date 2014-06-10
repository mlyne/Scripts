#!/usr/bin/perl -w

use strict;
use warnings;
#use LWP;

use InterMine::Item::Document;
use InterMine::Model;

my $usage = "usage: $0 nicolas_expression_tab bsub_blast_file

\n";

my ($expr_file, $blast_file, $model_file) = @ARGV;
#my $out_file = $ARGV[1];

unless ( $ARGV[1] ) { die $usage }

open(EXP_FILE, "< $expr_file") || die "cannot open $expr_file: $!\n";
open(BLAST_FILE, "< $blast_file") || die "cannot open $blast_file: $!\n";

my %blast_res;
my $chromosome;
while (<BLAST_FILE>) {
  my ($blast_q, $genome, undef, undef, undef, undef, 
    + undef, undef, $st_coord, $end_coord, $other) = split("\t", $_, 11);
  
  $genome =~ /.+\|(.+)\|/;
  $chromosome = $1;
  
  my ($start, $end, $strand);
  if ($st_coord > $end_coord) {
    $start = $end_coord;
    $end = $st_coord;
    $strand = "-1";
  } else {
    $start = $st_coord;
    $end = $end_coord;
    $strand = "1";
  }

  $blast_res{"$blast_q"} = [$start, $end, $strand];
}
close (BLAST_FILE);

my %bad_symbols;
my $non_unique_symbols = "ydzW ydzT fabG yrdD appA aroE carB cbiO def hemD iscS ispA nagP natA natB nrdF nrdI pgsA ppnK rpmG rpsN sat sfp swrAA thyA tuaA ydhU ydzS yetI ymfK ymzE yoyK ypqP ypuC yqbN yusY yxiT";
my @non_unique_symbols = split(" ", $non_unique_symbols);

for my $bad (@non_unique_symbols) {
  $bad_symbols{$bad}++;
}
#open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";

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

my %seen_genes;
for my $entry (@matrix)
{
#  chomp $entry;
  my ($id, $strand, $posV3, $posV3min, $posV3max, $multdbtbs, 
  + $comp, $sig, $pcomp, $psig, $xcortree, $SigmaFactorBS, $chipUnb, 
  + $chipMnb, $clcortreeUC, $clcortreeUB, $clcortreeUA, $VarExp, 
  + $VarExpPropUnexpl, $beginTU, $endTUshort, $endTUlong, $listShort, $listLong) = split("\t", $entry);

  $id = uc($id);

# process co-ordinates from blast results
  my ($start_found, $end_found, $strand_found);
  if (exists $blast_res{$id}) {
#    print join(", ", @{ $blast_res{$id} }), "\n";
    $start_found = $blast_res{$id}->[0];
    $end_found = $blast_res{$id}->[1];
    $strand_found = $blast_res{$id}->[2];

# process predicted Sigma Factors and split any that have multi-assignments
    my $pred_sig_factor = ($sig !~ m/Sig-/) ? $sig : undef;

    my ($prefix, $chars, @chars, @pred_sig_factors);
    if ($pred_sig_factor) {
      if ($pred_sig_factor =~ /^(Sig)([A-Z]+)/) {
	$prefix = $1;
	$chars = $2;
	@chars = split(//, $chars);
	@pred_sig_factors = map { "Sig$_" } @chars;
      } else {
	push (@pred_sig_factors, $pred_sig_factor);
      } 
    }

# make predicted sigma factor items
    my @pred_sig_objects;
    if (@pred_sig_factors) {
      for my $factor (@pred_sig_factors) {
	my $pred_sig_item = make_item(
	  PredictedSigmaFactor => (
	    identifier => "$factor",
	    probability => "$psig",
	  ),
	);
        push (@pred_sig_objects, $pred_sig_item); # array of sigma factor items
      }
    }

# process predicted Sigma Factor Binding sites and split any that have multi-assignments
    my $sig_Bsite = ($multdbtbs !~ m/-/) ? $multdbtbs : undef;

    my @sig_Bsites;
    if ($sig_Bsite) {
      if ($sig_Bsite =~ m/,/) {
	@sig_Bsites = split(/,/, $sig_Bsite);
      } else {
	push (@sig_Bsites, $sig_Bsite);
      } 
    }

# make sigma factor binding site items
    my @sig_Bsite_objects;
    if (@sig_Bsites) {
      for my $sig_bs (@sig_Bsites) {
	my $sig_bsite_item = make_item(
	  SigmaBindingSite => (
	    identifier => "$sig_bs",
	  ),
	);
        push (@sig_Bsite_objects, $sig_bsite_item); # array of sigma factor binding items
      }
    }


    my @genes = split(", ", $listShort);

    my ($gene_id, $promoter_id);
    for my $gene (@genes) {
      next if ($gene =~ /^S\d+/);
      $gene_id = $gene;
      $promoter_id = $id . "_" . $gene_id . "_" .$taxon_id;
      last;
    }

    next unless $gene_id;
    next if (exists $bad_symbols{$gene_id});
    next if ($gene_id =~ /NA/);

  ############################################
  # Set info for gene 
    my $gene_item;
    unless (exists $seen_genes{$gene_id}) {
      $gene_item = make_item(
	  Gene => (
	      symbol => "$gene_id",
	  ),
      );
    }


  ############################################
  # Set info for seuence 
    my $seq_item = make_item(
	Sequence => (
	    'length' => $seq_length,
	    residues => "$SigmaFactorBS",
	),
    );

    my $location_item = make_item(
	Location => (
	    start => "$start_found",
	    end => "$end_found",
	    strand => "$strand_found",
	    dataSets => [$data_set_item],
	),
    );

# 	  predictedSigmaFactor => $pred_sig_factor,
   my $promoter_item = make_item(
       NicolasPromoter => (
	  primaryIdentifier => $promoter_id,
	  predictedCluster => $comp,
	  clusterProbability => $pcomp,
	  chromosome => $chromosome_item,
	  chromosomeLocation => $location_item,
	  sequence => $seq_item,
	  dataSets => [$data_set_item],
       ),
   );

    if (exists $seen_genes{$gene_id}) {
      $promoter_item->set( gene => $seen_genes{$gene_id} );
    } else {
      $promoter_item->set( gene => $gene_item );
    }

   $seen_genes{$gene_id} = $gene_item unless (exists $seen_genes{$gene_id});

   for (@sig_Bsite_objects) {
    $_->{promoter} = $promoter_item;
   }
   for (@pred_sig_objects) {
    $_->{promoter} = $promoter_item;
   }

  $promoter_item->set( predictedSigmaFactors => \@pred_sig_objects ) if @pred_sig_objects;
  $promoter_item->set( sigmaBindingSites => \@sig_Bsite_objects ) if @sig_Bsite_objects;

 }
}

$doc->close(); # writes the xml
exit(0);

######## helper subroutines:

sub make_item {
    my @args = @_;
    my $item = $doc->add_item(@args);
    if ($item->valid_field('organism')) {
        $item->set(organism => $org_item);
    }
    return $item;
}
