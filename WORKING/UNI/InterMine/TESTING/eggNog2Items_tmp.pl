#!/usr/bin/env perl
use strict;
use warnings;

use feature ':5.12';

use InterMine::Item::Document;
use InterMine::Model;

my $usage = "eggNog2ItemsXML.pl <taxon_file> <im_model_file.xml>


";

my ($taxon_file, $model_file) = @ARGV;
unless ( $ARGV[1] ) { die $usage }

### Files to process
#my $base_url = "/home/ml590/MIKE/InterMine/SynBioMine/DataSources/EggNog/";
my $base_url = "/SAN_synbiomine/data/eggnog/ParseData/";

my $id_file = $base_url . "id_conversion_taxons.txt"; ## this is a subset of id_conversion.tsv 
# that's had the relevant taxons extracted. Original file is > 3.3G!
# See the README_eggnog_files.txt for method

my $nog_members = $base_url . "bactNOG.members.txt";
my $nog_funccat = $base_url . "bactNOG.funccat.txt";
my $nog_description = $base_url . "bactNOG.description.txt";
my $funccat_divisions = $base_url . "eggnogv4.funccats.txt";

my $model = new InterMine::Model(file => $model_file);
my $doc = new InterMine::Item::Document(model => $model);

my $data_source_item = make_item(
    DataSource => (
        name => "EggNOG: evolutionary genealogy of genes",
	url => "http://eggnog.embl.de/",
    ),
);

my $ortholog_data_set_item = make_item(
    DataSet => (
        name => "EggNOG Non-supervised Orthologous Groups",
	dataSource => $data_source_item,
    ),
);

my $funccat_data_set_item = make_item(
    DataSet => (
        name => "EggNOG Functional Categories",
	dataSource => $data_source_item,
    ),
);

# set up a set of items tracking hashes
my(%seen_funccat_items, %seen_gene_items, %seen_nog_items, %seen_organism_items);

# For testing
# # my @taxon_list = qw|1392 83333 224308 1133852 691437
# #  260799 941639 1111068 592022 198094 544556 315750 272558
# #  585056 326423 685038 279010 471223 634956 585057 226900
# #  581103 649639 66692 550542 315749 398511 281309 511145
# #  420246 1367477 720555 235909 666686 315730 527000 386585 439292 585054|;

### Process Taxons file
# File format
# id1 id2 id3 ... id(n)

open my $taxons_fh, "$taxon_file" or die "can't open file: $taxon_file $!\n";
my @taxon_list = split(" ", <$taxons_fh>);
close ($taxons_fh);

### Process functional categories file
# eggnogv4.funccats.txt File format
# INFORMATION STORAGE AND PROCESSING
#  [J] Translation, ribosomal structure and biogenesis 
#  [A] RNA processing and modification 
#  [K] Transcription 
#  [L] Replication, recombination and repair 
#  [B] Chromatin structure and dynamics 
# 
# split on empty line

open my $funccat_fh, "$funccat_divisions" or die "can't open file: $funccat_divisions $!\n";

my @cats = do { local $/ = ''; <$funccat_fh> }; # split filehandle on empty line into array

my %major_funccat;
for my $cat (@cats) {
  my @cat_divisions = split("\n", $cat);

  my $division = shift(@cat_divisions);

  for my $category (@cat_divisions) {
    my ($letter, $description) = split('] ', $category);
    $letter =~ s/ \[//;
    $description =~ s/ $//;
    $major_funccat{$letter} = [ lc($description), lc($division) ];
    
    &make_funccat_items($letter, lc($description), lc($division), $funccat_data_set_item);
  }
}
close ($funccat_fh);


### Process EggNOG descriptions file
# File format
# EggNogID \t category description

my %nog_descriptions;
open my $nogdesc_fh, "$nog_description" or die "can't open file: $nog_description $!\n";

while (<$nogdesc_fh>) {
  chomp;
  my ($nogID, $description) = split("\t", $_);
  $description = ($description) ? $description : "No description";
  $nog_descriptions{$nogID} = $description;

  &make_nogDesc_item($nogID, $description, $ortholog_data_set_item);
}

close ($nogdesc_fh);

# for my $key (keys %nog_descriptions) {
#   say $key, "\t", $nog_descriptions{$key};
# }

### Process file which maps EggNogIDs to functional categories
# File format
# EggNogID \t AB    [joined_classifiers - belongs to categories A & B ]

my (%funccats);
open my $nogCat_fh, "$nog_funccat" or die "can't open file: $nog_funccat $!\n";

while (<$nogCat_fh>) {
  chomp;
  my ($nog_cat, $funccats) = split("\t");

  my @cats;
  if ( length($funccats) > 1 ) {
    @cats = split('', $funccats);
  } else {
    push(@cats, $funccats);
  }
  $funccats{$nog_cat} = \@cats;
}

close ($nogCat_fh);

for my $key (keys %funccats) {
  for my $category ( @{ $funccats{$key} } ) {
    my $category_item = $seen_funccat_items{$category} if ( exists $seen_funccat_items{$category} );

    if ( exists $seen_nog_items{$key} ) {
      push( @{ $seen_nog_items{$key}->{'functionalCategories'} }, $category_item );

      my $nog_item = $seen_nog_items{$key};
      push( @{ $seen_funccat_items{$category}->{'eggNogCategories'} }, $nog_item );
    }
  }
}

### Process ID conversion file 
# This contains mappings of eggNog organism identifiers to stable organism ID
# File format:
# taxID \t eggNogOrgID \t stableID \t source
# 224308  Bsubs1_010100000080     bsu:BSU00160    BLAST_KEGG_ID
# I've chosen BLAST_KEGG_ID as these correspond to genbank unique locus_tag identifiers

my (%id_lookup);
open my $id_fh, "$id_file" or die "can't open file: $id_file $!\n";

while (<$id_fh>) {
  chomp $_;

  my ($taxon_id, $nog_id, $kegg_id, undef) = split("\t", $_);
  my ($kegg_org, $org_id) = split(":", $kegg_id);
  my $taxon_nogID = $taxon_id . "\." . $nog_id;
  $id_lookup{$taxon_nogID} = $org_id;

}

close ($id_fh);

### Process file of NOG nog_members
# File format:
# EggNogID \t taxon.eggNogOrgID \t prot_start \t prot_end
# We use this with the ID conversion file above to resolve
# orthologue group members to their stable gene IDs

open my $nog_fh, "$nog_members" or die "can't open file: $nog_members $!\n";

while (<$nog_fh>) {
  chomp $_;
  
  my ($nog_cat, $member_nog_id, $start, $end) = split("\t", $_);
  my ($taxon, $nog_id) = split('\.', $member_nog_id);

  if ( exists $id_lookup{$member_nog_id} ) {
    my $gene_id = $id_lookup{$member_nog_id};

    my $gene_item = &make_gene_item($gene_id, $taxon);

    if ( exists $seen_nog_items{$nog_cat} ) {
      push( @{ $seen_nog_items{$nog_cat}->{'genes'} }, $gene_item );

      my $nog_item = $seen_nog_items{$nog_cat};
      push( @{ $seen_gene_items{$gene_id}->{'eggNogCategories'} }, $nog_item );
    }

#    say $nog_cat, " ", $taxon, " ", $id_lookup{$member_nog_id};
  }
}

#for my $key (keys %id_lookup) {
#  say $key, "\t", $id_lookup{$key};
#}

close ($nog_fh);


$doc->close(); # writes the xml
exit(0);

######### helper subroutines:

sub make_item {
    my @args = @_;
    my $item = $doc->add_item(@args);
#     if ($item->valid_field('organism')) {
#         $item->set(organism => $org_item);
#     }
    return $item;
}

sub make_funccat_items {
  my($letter, $description, $division, $funccat_data_set_item) = @_;
  my $funccat_item = make_item(
    FunctionalCategory => (
	classifier => $letter,
	name => $description,
	category => $division,
	dataSets => [$funccat_data_set_item], 
    ),
  );

  $seen_funccat_items{$letter} = $funccat_item;

}

sub make_nogDesc_item {

  my ($nogID, $description, $ortholog_data_set_item) = @_;
  my $nogDesc_item = make_item(
    EggNogCategory => (
	primaryIdentifier => $nogID,
	description => $description,
	dataSets => [$ortholog_data_set_item], 
    ),
  );

  $seen_nog_items{$nogID} = $nogDesc_item;

}

sub make_organism_item {
  my $org_item;
  my $taxon = shift;
  
  if ( exists $seen_organism_items{$taxon} ) {
    $org_item = $seen_organism_items{$taxon};
  } else {
    $org_item = make_item(
      Organism => (
	taxonId => $taxon,
      ),
    );
    $seen_organism_items{$taxon} = $org_item;
  }

  return $org_item;
}

sub make_gene_item {
  my $gene_item;
  my ($gene_id, $taxon) = @_;

  my $org_item = &make_organism_item($taxon);
    
  if ( exists $seen_gene_items{$gene_id} ) {
       $gene_item = $seen_gene_items{$gene_id};
  } else {
    $gene_item = make_item(
      Gene => (
	primaryIdentifier => $gene_id,
	organism => $org_item,
      ),
    );
    $seen_gene_items{$gene_id} = $gene_item;
  }

  return $gene_item;
}
