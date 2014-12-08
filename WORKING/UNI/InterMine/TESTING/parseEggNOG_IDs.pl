#!/usr/bin/env perl
use strict;
use warnings;

use feature ':5.12';

my $usage = "script.pl

";

my @taxon_list = qw|1392 83333 224308 1133852 691437
 260799 941639 1111068 592022 198094 544556 315750 272558
 585056 326423 685038 279010 471223 634956 585057 226900
 581103 649639 66692 550542 315749 398511 281309 511145
 420246 1367477 720555 235909 666686 315730 527000 386585 439292 585054|;

my $base_url = "/home/ml590/MIKE/InterMine/SynBioMine/DataSources/EggNog/";

my $id_file = $base_url . "test_ids_2.txt";
my $nog_members = $base_url . "test_members.txt";
my $nog_funccat = $base_url . "bactNOG.funccat.txt";
my $nog_description = $base_url . "bactNOG.description.txt";
my $funccat_divisions = $base_url . "eggnogv4.funccats.txt";

open my $funccat_fh, "$funccat_divisions" or die "can't open file: $funccat_divisions $!\n";

# eggnogv4.funccats.txt File format
# INFORMATION STORAGE AND PROCESSING
#  [J] Translation, ribosomal structure and biogenesis 
#  [A] RNA processing and modification 
#  [K] Transcription 
#  [L] Replication, recombination and repair 
#  [B] Chromatin structure and dynamics 
# 
# split on empty line

my @cats = do { local $/ = ''; <$funccat_fh> }; # split filehandle on empty line into array

my %major_funccat;
for my $cat (@cats) {
  my @cat_divisions = split("\n", $cat);

  my $division = shift(@cat_divisions);

  for my $category (@cat_divisions) {
    my ($letter, $description) = split('] ', $category);
    $letter =~ s/ \[//;
    $major_funccat{$letter} = [ lc($description), lc($division) ];
  }
}
close ($funccat_fh);

my %nog_descriptions;
open my $nogdesc_fh, "$nog_description" or die "can't open file: $nog_description $!\n";

while (<$nogdesc_fh>) {
  chomp;
  my ($nogID, $description) = split("\t", $_);
  $description = ($description) ? $description : "No description";
  $nog_descriptions{$nogID} = $description;
}

close ($nogdesc_fh);

# for my $key (keys %nog_descriptions) {
#   say $key, "\t", $nog_descriptions{$key};
# }

my (%id_lookup, %funccats);
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

#for my $key (keys %funccats) {
#  say $key, "\t", join(";", @{ $funccats{$key} } );
#}

open my $id_fh, "$id_file" or die "can't open file: $id_file $!\n";

while (<$id_fh>) {
  chomp $_;

  for my $taxon (@taxon_list) {
    if ( ($_ =~ /^$taxon\t/) && ($_ =~ /BLAST_KEGG_ID/ ) ) {
      my ($taxon, $nog_id, $kegg_id, undef) = split("\t", $_);
      my ($kegg_org, $org_id) = split(":", $kegg_id);
      my $taxon_nogID = $taxon . "\." . $nog_id;
      $id_lookup{$taxon_nogID} = $org_id;
    }
  }
}

close ($id_fh);

open my $nog_fh, "$nog_members" or die "can't open file: $nog_members $!\n";

while (<$nog_fh>) {
  chomp $_;
  
  my ($nog_cat, $member_nog_id, $start, $end) = split("\t", $_);
  my ($tax, $nog_id) = split('\.', $member_nog_id);

  if ( exists $id_lookup{$member_nog_id} ) {
#    say $nog_cat, " ", $tax, " ", $id_lookup{$member_nog_id};
  }
}

#for my $key (keys %id_lookup) {
#  say $key, "\t", $id_lookup{$key};
#}

close ($nog_fh);
