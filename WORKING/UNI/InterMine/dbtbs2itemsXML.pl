#!/usr/bin/perl

use strict;
use warnings;
use XML::Twig;
use Getopt::Std;

use feature ':5.12';

use InterMine::Item::Document;
use InterMine::Model;

use SynbioGene2Location qw/geneLocation/;
use SynbioRegionSearch qw/regionSearch/;

# Print unicode to standard out
binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

my $usage = "Usage:parseDBTBS.pl DBTBS_XML.xml InterMine_model OUT_FILE

";

### command line options ###
my (%opts, $debug);

getopts('hd', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"d"} and $debug++;

unless ( $ARGV[2] ) { die $usage };

# specify and open query file (format: )
my ($xml_file, $model_file, $out_file) = @ARGV;

# synonyms file downloaded from bacilluscope: ids, symbols and synonyms extracted
my $synonyms_file = "/home/ml590/MIKE/InterMine/SynBioMine/DataSources/DATA/bsub_id_symbol_synonyms_May2014.txt";

open(SYN_FILE, "< $synonyms_file") || die "cannot open $synonyms_file: $!\n";

# process id, symbol, synonyms file
my %id2synonym; # hash lookup for symbols/ synonyms
my %seen_genes; # store genes that have been resolved to unique identifiers
my %seen_refs; # store of refs that have already been processed
my %seen_promoters; # store promoter ids so that we can create unique identifiers
my %seen_gene_items; # track processed gene items
my %seen_ref_items; # track processed reference items
my %seen_tfac_items;
my %evidenceCode_items;


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

open OUT_FILE, ">$out_file" or die $!; 

my $taxon_id = "224308";
my $title = "DBTBS - Regulatory features for Bacillus subtilis 168";
my $url = "http://dbtbs.hgc.jp";
my $chromosome = "NC_000964.3";

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
	url => $url,
    ),
);

my $data_set_item = make_item(
    DataSet => (
        name => "DBTBS Promoters for taxon id: $taxon_id",
	dataSource => $data_source_item,
    ),
);

my $chromosome_item = make_item(
    Chromosome => (
        primaryIdentifier => $chromosome,
    ),
);


my $twig = XML::Twig->new(
    twig_handlers => {
        'dbtbs/promoter' => \&process_promoters,
        'dbtbs/tfacs' => \&process_tfac,
        'dbtbs/operon' => \&process_operon,
    },
);

$twig->parsefile( "$xml_file" );


$doc->close(); # writes the xml
exit(0);

# 
close OUT_FILE;

sub process_promoters {
  my ($twig, $entry) = @_;

  say "PROMOTER: \t" if ($debug);
  
  my $gene_DBTBS = ( $entry->first_child( 'gene' ) ) ? $entry->first_child( 'gene' )->text : undef;
  my $tfac = ( $entry->first_child( 'tfac' ) ) ? $entry->first_child( 'tfac' )->text : undef;
  my $sigma = ( $entry->first_child( 'sigma' ) ) ? $entry->first_child( 'sigma' )->text : undef;
  my $id = ( $entry->first_child( 'name' ) ) ? $entry->first_child( 'name' )->text : undef;
  my $regulation = ( $entry->first_child( 'regulation' ) ) ? $entry->first_child( 'regulation' )->text : undef;
  my $prom_seq = ( $entry->first_child( 'sequence' ) ) ? $entry->first_child( 'sequence' )->text : undef;
  my $location = ( $entry->first_child( 'location' ) ) ? $entry->first_child( 'location' )->text : undef;

  my @refs = $entry->children( 'reference' );

  $id =~ s/,/_/g;
  
  $prom_seq =~ tr|[A-Z]|[a-z]|;
  $prom_seq =~ s|\{(.+?)\}|uc($1)|eg;
  $prom_seq =~ s|\/(.+)\/|uc($1)|eg;

  my $query = ">$gene_DBTBS\n$prom_seq";
  my $seq_len = &seq_length( $prom_seq ) if ($prom_seq);

  my $region_ref = &run_BLAST( $query, $seq_len ) if ($prom_seq);
  my @prom_regions = @{ $region_ref } if ($region_ref);

  my $region;
  if ( scalar(@prom_regions) > 1) {
    warn "Sequence is not unique: $prom_seq\n";
    next;
  } else {
    $region = $prom_regions[0];
  }

  $region =~ m/(.+)\:(.+)\.\.(.+) (.+)/; 
  my ($chr, $start, $end, $strand) = ($1, $2, $3, $4);

  my ($geneDBidentifier, $tfacDBidentifier, $sigmaDBidentifier);
  $geneDBidentifier = &resolver($gene_DBTBS, $region);
  next unless ($geneDBidentifier);
  $tfacDBidentifier = &resolver($tfac, undef) if $tfac;
  $sigmaDBidentifier = &resolver($sigma, undef) if $sigma;

# generate a unique identifier for each promoter
  my $promoter_id = $gene_DBTBS . "_" . $geneDBidentifier . "_" . $taxon_id;
  $seen_promoters{$promoter_id}++;
  
  my $promoter_uid = $promoter_id . "_" . $seen_promoters{$promoter_id};

  my $refsRef = &process_refs(\@refs);
  my @evidence = @{ $refsRef };

  say "UID: $promoter_uid" if ($debug);

  say OUT_FILE "UID: $promoter_uid";
  say OUT_FILE "Synonym: $id" if ($id);
  say OUT_FILE "Gene: $gene_DBTBS $geneDBidentifier";
  say OUT_FILE "Sigma: $sigma $sigmaDBidentifier" if ($sigma);
  say OUT_FILE "Sequence: $prom_seq" if ($prom_seq);
  say OUT_FILE "SeqLen: $seq_len" if ($prom_seq);
  say OUT_FILE "Region: $chr, $start, $end, $strand" if ($region);
  say OUT_FILE "Location: $location" if ($location);
  say OUT_FILE "Tfac: $tfac $tfacDBidentifier" if ($tfac);
  say OUT_FILE "Reg: $regulation" if ($regulation);

  if (@evidence) {
    say OUT_FILE "Evidence: ", join("; ", @evidence);
  }
  
  $twig->purge();
}

sub process_tfac {
  my ($twig, $entry) = @_;

# #  say OUT_FILE "TF: \t";

# #   my $gene_tfac = ( $entry->first_child( 'gene' ) ) ? $entry->first_child( 'gene' )->text : undef;
# #   my $tf_type = ( $entry->first_child( 'tf_type' ) ) ? $entry->first_child( 'tf_type' )->text : undef;
# #   my $domain = ( $entry->first_child( 'domain' ) ) ? $entry->first_child( 'domain' )->text : undef;
# #   my $tf_seq = ( $entry->first_child( 'sequence' ) ) ? $entry->first_child( 'sequence' )->text : undef;
# #   my $comment = ( $entry->first_child( 'comment' ) ) ? $entry->first_child( 'comment' )->text : undef;

# #   say OUT_FILE "$gene_tfac $tf_type $domain";
# #   say OUT_FILE $tf_seq;
# #   say OUT_FILE $comment;

  $twig->purge();
}

sub process_operon {
  my ($twig, $entry) = @_;

#  say OUT_FILE "\nOPERON: \t";

# #   my $id = ( $entry->first_child( 'name' ) ) ? $entry->first_child( 'name' )->text : undef;
# #   my $gene_operon = ( $entry->first_child( 'genes' ) ) ? $entry->first_child( 'genes' )->text : undef;
# #   my @operon_genes = split(',', $gene_operon);
# # 
# #   my $experiment = ( $entry->first_child( 'experiment' ) ) ? $entry->first_child( 'experiment' )->text : undef;
# #   my $comment = ( $entry->first_child( 'comment' ) ) ? $entry->first_child( 'comment' )->text : undef;
# # 
# #   my ($term_seq, $energy);
# #   my $terminator = $entry->first_child( 'terminator' );
# #   if ($terminator) {
# #     $term_seq = ( $terminator->first_child( 'stemloop' ) ) ? $terminator->first_child( 'stemloop' )->text : undef;
# #     $energy = ( $terminator->first_child( 'energy' ) ) ? $terminator->first_child( 'energy' )->text : undef;
# #   }

# #   my $query_seq = $term_seq;
# #   $query_seq =~ s/\{.+?\}//g;
# #   say OUT_FILE "TERMseq: ", $term_seq;
# # 
# #   my $term_query = ">$id\n$query_seq\n";
# #   my $seq_len = &seq_length( $query_seq ) if ($query_seq);
# # 
# #   my $region_ref = &run_BLAST( $term_query, $seq_len ) if ($query_seq);
# #   my @term_regions = @{ $region_ref } if ($region_ref);
# # 
# #   say OUT_FILE "$id ", join("\.", @operon_genes), " $experiment";
# #   say OUT_FILE $comment;
# # 
# #   say OUT_FILE "TERM_REGION: ", join("; ", @term_regions);
# # 
# #   my @refs = $entry->children( 'reference' );
# #   &process_refs(\@refs);

  $twig->purge();
}

sub process_refs {
  my $arrRef = shift;
  my @refs = @$arrRef;

  my @processed_refs;

   foreach my $ref (@refs) {
    my $experiment = ( $ref->first_child( 'experiment' ) ) ? $ref->first_child( 'experiment' )->text : undef;
    my $pmid = ( $ref->first_child( 'pubmed' ) ) ? $ref->first_child( 'pubmed' )->text : undef;
    my $author = ( $ref->first_child( 'author' ) ) ? $ref->first_child( 'author' )->text : undef;
    my $year = ( $ref->first_child( 'year' ) ) ? $ref->first_child( 'year' )->text : undef;
    my $title = ( $ref->first_child( 'title' ) ) ? $ref->first_child( 'title' )->text : undef;
    my $genbank = ( $ref->first_child( 'genbank' ) ) ? $ref->first_child( 'genbank' )->text : undef;
    my $link = ( $ref->first_child( 'link' ) ) ? $ref->first_child( 'link' )->text : undef;

    my ($evidenceRefs, @evidence_codes);
    if ($experiment) {
      @evidence_codes = split(" ", $experiment);
      $evidenceRefs = &evidence_lookup(\@evidence_codes);
    }

    my @evidence_descriptions = @{ $evidenceRefs }; 

    $author =~ s/\&amp\;/and/g;
    $author =~ s/, et al\.//g;

#    say OUT_FILE "\t"; 
#    say OUT_FILE $evidence if ($experiment);

    if ($pmid) {
      if (exists $seen_ref_items{$pmid}) {
	say "Already seen $pmid. Reusing @{ $seen_refs{$pmid} }" if ($debug);
#	say OUT_FILE "seen ref\t", @{ $seen_refs{$pmid} };
	push(@processed_refs, $seen_ref_items{$pmid} );
      } else {
	my $publication_item = &make_item(
	  Publication => (
	    pubMedId => $pmid,
	    firstAuthor => $author,
	    year => $year,
	  ),
	);

	my $evidence_item = &make_item(
	  PromoterEvidence => (
	    publications => [ $publication_item ],
	    evidenceCodes => $evidenceRefs,
	  ),
	);
	$seen_ref_items{$pmid} = $evidence_item;
	push(@processed_refs, $seen_ref_items{$pmid});
	say OUT_FILE "new ref\t$author $year $pmid", join("; ", @evidence_descriptions) if ($debug);
      }
    } 
    elsif ( $title ) {
     if (exists $seen_ref_items{$title}) {
	say "Already seen $title. Reusing @{ $seen_refs{$title} }" if ($debug);
#	say OUT_FILE "seen ref\t", @{ $seen_refs{$title} };
	push(@processed_refs, $seen_ref_items{$title});
      } else {
	my $publication_item = &make_item(
	  Publication => (
	    title => $title,
	    firstAuthor => $author,
	    year => $year,
	  ),
	);

	my $evidence_item = &make_item(
	  PromoterEvidence => (
	    publications => [ $publication_item ],
	    evidenceCodes => $evidenceRefs,
	  ),
	);
	$seen_ref_items{$title} = $evidence_item;
	push(@processed_refs, $seen_ref_items{$title});
      }
    } 
    elsif ( $link ) {
      say OUT_FILE "\t$author $link"; # only operon refs
    } 
    else {
      say OUT_FILE "\t$genbank"; # only operon refs
    }
  }
  return \@processed_refs;
}


sub seq_length {
  my $in = shift;
  my $length = length($in);
}

sub run_BLAST {

  my ($query, $len) = @_;

  # Set working directory
  my $work_dir = "/home/ml590/MIKE/InterMine/SynBioMine/DataSources/DATA/BLAST/Bsub168";

  ### TEST DATA ###
  #my $query = ">test1\natgcagaccccgcacattcttatcgttgaagacgagttggtaacacg"; # test seq
  #my $query = ">test2\natgctgcggggcattcaaaattgaagaaaaggtaacacg"; # test fail seq
  # >nlpD\nTTCAGTAGGGTGCCTTGCACGGTAATTATGTCACTGG
  # >gcvR\nTTGTATGCATGTTTTTTTTATGCTTTCCTTAAGAACA";

  # write query to a tmp file
  open TMP_FILE, ">$work_dir/tmp_file.fa" or die $!; 
  say TMP_FILE $query;
  close TMP_FILE;

  # set BLAST params
  #-task blastn-short
  #say "BLASTing sequence: $part_sequence\n"; ###
  my $blast_db = "$work_dir/Bsubtilis_168_refSeq";
  my $blast_out;

  if ($len <= 30) {
    warn "SHORT sequence ($len) - using blastn-short $query\n" if ($debug);
    $blast_out = `blastn -query $work_dir/tmp_file.fa -db $blast_db -task blastn-short -evalue 1e-1 -dust no -ungapped -outfmt 6`;
  }
  else {
    $blast_out = `blastn -query $work_dir/tmp_file.fa -db $blast_db -evalue 1e-1 -dust no -ungapped -outfmt 6`;
  }

  say "Blast res: ", $blast_out if ($debug); ###

  my @blast_res;
  if ($blast_out =~ m/\n/) {
    @blast_res = split("\n", $blast_out);
  } else {
    push(@blast_res, $blast_out);
  }
  #say join("\n", @blast_res), "\n";

  # BLAST output 
  # Field	 	Description
  # 1	 	Query label.
  # 2	 	Target (database sequence or cluster centroid) label.
  # 3	 	Percent identity.
  # 4	 	Alignment length.
  # 5	 	Number of mismatches.
  # 6	 	Number of gap opens.
  # 7	 	1-based position of start in query. For translated searches (nucleotide queries, protein targets), query start<end for +ve frame and start>end for -ve frame.
  # 8	 	1-based position of end in query.
  # 9	 	1-based position of start in target. For untranslated nucleotide searches, target start<end for plus strand, start>end for minus strand.
  # 10	 	1-based position of end in target.
  # 11	 	E-value calculated using Karlin-Altschul statistics.
  # 12	 	Bit score calculated using Karlin-Altschul statistics.

  my @regions;
  for my $result (@blast_res) {
    my ($q_name, $targ, $perc, $a_len, $mism, $gap, 
      + $q_start, $q_end, $db_start, $db_end, $other) = split("\t", $result, 11);

  unlink "$work_dir/tmp_file.txt";

  # Test to see if we have results
    unless ($perc) {
      warn "No BLAST hits for QUERY: $query\n" if ($debug);
      return;
    }

  # grab host chromosome info ready for synbiomine query
    my $chromosome;
    if ($targ =~ /\|(NC_.+)\|/) {
      $chromosome = $1;
    } else {
      warn "No Chromosome found for $targ\n" if ($debug);
      return;
    }

  # query region co-ordinates
    my ($organism_start, $organism_end, $organism_strand);

  # check co-ord to get strand info
    if ($db_start < $db_end) {
      $organism_start = $db_start;
      $organism_end = $db_end;
      $organism_strand = "1";
    } else {
      $organism_start = $db_end;
      $organism_end = $db_start;
      $organism_strand = "-1";
    }

    my $region = "$chromosome:$organism_start..$organism_end $organism_strand";

    if ($a_len != $len) {
      warn "Partial match: $q_name match length ($a_len) less than query length ($len)\n" if ($debug);
      return \@regions;
    }

    if ($perc > 95) {
      push(@regions, $region);
      say "BlastRes used: ", $result if ($debug);
    } else {
      warn "$q_name: BLAST hit for $region below cutoff: ", $perc, " percent identity\n" if ($debug);
      return \@regions;
    }
  }
  return \@regions;
}

sub gene_lookup {

  my ($gene_DBTBS, $region) = @_;

  my ($synbioRef, @identifiers);
  if ( exists $seen_genes{$gene_DBTBS} ) {
    warn "Great! Already seen $gene_DBTBS. Reusing resolved ID...\n" if ($debug);
    push (@identifiers, $seen_genes{$gene_DBTBS});
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

  if ( exists $id2synonym{$gene_DBTBS} ) {
    if (scalar( @{ $id2synonym{$gene_DBTBS} } > 1) ) {
      warn "$gene_DBTBS is not unique: ", join("; ", @{ $id2synonym{$gene_DBTBS} }), "\n" if ($debug);

      if ($region) {
	warn "Checking region ($extend_region) against SynBioMine...", "\n" if ($debug);

# # call a module to query synbiomine regioSearch for gene id
	my ($org_short, $geneRef) = regionSearch($extend_region);
	my @genes_synbio = @$geneRef;

	foreach my $synbio_gene (@genes_synbio) {
	  my $symbol = $synbio_gene->[0];
	  my $identifier = $synbio_gene->[1];
	  push (@identifiers, $identifier);
	  warn "Found: $gene_DBTBS matches S: $symbol\tID: $identifier\n" if ($debug);
	}

      } else {
	warn "No region - searching SynBioMine by ID...\n" if ($debug);
	my $geneRef = $id2synonym{$gene_DBTBS};
	$synbioRef = &synbiomine_genes($gene_DBTBS, $geneRef, $region);
      }

    } else {
      warn "Match: $gene_DBTBS matches: ", $id2synonym{$gene_DBTBS}->[0], "\n" if ($debug);
      my $match = $id2synonym{$gene_DBTBS}->[0];
      push (@identifiers, $match);
    }
  } else {
    warn "Can't find $gene_DBTBS in lookup. Checking SynBioMine...\n" if ($debug);
    my $geneRef = [ $gene_DBTBS ];
    $synbioRef = &synbiomine_genes($gene_DBTBS, $geneRef, $region);
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
      warn "Houston, we have an ambiguity problem: $id\n" if ($debug);
    } else {
      my $identifier = $gene_lookups[0]->[0];
      my $symbol = $gene_lookups[0]->[1];

      if ( ($symbol) && ($symbol eq $symbol2check) ) {
	warn "Symbols match: $symbol eq $symbol2check - resolving to $identifier\n" if ($debug);
	push (@identifiers, $identifier);
	return \@identifiers;
      } 
      elsif ( ($symbol) && ($symbol ne $symbol2check) ) {
	warn "Symbols don't match: $symbol eq $symbol2check - can't resolve $identifier\n" if ($debug);
#	push (@identifiers, $identifier);
      }
      else {
	warn "$id not found in synbiomine!\n" if ($debug);
      }
    }
  }

  if (@identifiers) {
    \@identifiers;
  } else { return; }

}

sub resolver {
  my ($symbol, $region) = @_;
  my $gene_DBTBS = lcfirst($symbol);

  my $geneLookupRef = &gene_lookup($gene_DBTBS, $region);
  my @geneDBids = @{ $geneLookupRef } if ($geneLookupRef);

  my $geneDBidentifier;
  if ($geneLookupRef) {
    for my $identifier (@geneDBids) {
      say "Success: $gene_DBTBS resolved to $identifier" if ($debug);
      $geneDBidentifier = $identifier;
      $seen_genes{$gene_DBTBS} = $identifier unless (exists $seen_genes{$gene_DBTBS});
    }
  } else {
    warn "Fail: Nothing returned from gene lookup with: $gene_DBTBS\n" if ($debug);
    return;
  }
  
  return $geneDBidentifier;

}

sub evidence_lookup {
  
  my $evidenceRef = shift;
  my @evidence_codes = @{ $evidenceRef };

  my %evidence = <<END =~ /(\w+)\t(.+)/g;
AR	DNA microarray and macroarray
CH	Chromatin immunoprecipitation microarray (ChIP-on-chip)
DB	Disruption of Binding Factor gene
DP	Deletion assay
FT	Footprinting assay (DNase I, DMS, etc.)
FP	Fluorecent protein
GS	Gel retardation assay
HB	Slot blot analysis
HM	Homology search
OV	Overexpression of Binding Factor gene
PE	Primer extension analysis
RG	Reporter gene (e.g., lacZ assay)
RO	Run-off transcription assay
ROMA	Run-off transcription followed by macroarray analysis
S1	S1 mapping analysis (S1 nuclease transcript mapping)
SDM	Site-directed mutagenesis (Oligonucleotide-directed mutagenesis)
NB	Northern Blot
ND	No Data
END



  my @evidenceCode_items;
  for my $code (@evidence_codes) {
    say "Code: ", $code;
    next unless (exists $evidence{$code});

    if (exists $evidenceCode_items{$code}) {
      my $item = $evidenceCode_items{$code};
      push(@evidenceCode_items, $item);
    } 
    else {
      my $evidenceCode_item = &make_item(
	PromoterEvidenceCode => (
	  abbreviation => $code,
	  name => $evidence{$code},
	),
      );
      $evidenceCode_items{$code} = $evidenceCode_item;
      push(@evidenceCode_items, $evidenceCode_item);
    }
  }

  return \@evidenceCode_items;

}

######## helper subroutines:

sub make_item {
    my @args = @_;
    my $item = $doc->add_item(@args);
    if ($item->valid_field('organism')) {
        $item->set(organism => $org_item);
    }
    return $item;
}
