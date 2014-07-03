#!/usr/bin/perl

use strict;
use warnings;
use XML::Twig;
use Getopt::Std;

use feature ':5.12';

use InterMine::Item::Document;
use InterMine::Model;

use BlastSynbio qw/run_BLAST/;
use SynbioGene2Location qw/geneLocation/;
use SynbioRegionSearch qw/regionSearch/;

# Print unicode to standard out
binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

my $usage = "Usage:dbtbs2itemsXML.pl DBTBS_XML.xml InterMine_model OUT_FILE

";

### command line options ###
my (%opts, $debug);

getopts('hd', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"d"} and $debug++;

unless ( $ARGV[2] ) { die $usage };

# specify and open query file (format: )
my ($xml_file, $model_file, $out_file) = @ARGV;

### Keep a track of processed identifiers and items
my %seen_genes; # store genes that have been resolved to unique identifiers
my %seen_refs; # store of refs that have already been processed
my %seen_promoters; # store promoter ids so that we can create unique identifiers
my %seen_gene_items; # track processed gene items
my %seen_ref_items; # track processed reference items
my %seen_tfac_items; # track processed tfac items
my %seen_sigma_items; # track processed tfac items
my %evidenceCode_items;
my %seen_publications_items;

# synonyms file downloaded from bacilluscope: ids, symbols and synonyms extracted
my $synonyms_file = "/home/ml590/MIKE/InterMine/SynBioMine/DataSources/bsub_id_symbol_synonyms_May2014.txt";
my $work_dir = "/home/ml590/MIKE/InterMine/SynBioMine/DataSources/BLAST/Bsub168";

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
  my $synonym = $id if ($id);
  
  $prom_seq =~ tr|[A-Z]|[a-z]|;
  $prom_seq =~ s|\{(.+?)\}|uc($1)|eg;
  $prom_seq =~ s|\/(.+)\/|uc($1)|eg;

  my $query = ">$gene_DBTBS\n$prom_seq";
  my $seq_length = &seq_length( $prom_seq ) if ($prom_seq);

# BLAST promoter seq against B. sub genome to get location
# Set working directory
#  my $work_dir = "/home/ml590/MIKE/InterMine/SynBioMine/DataSources/BLAST/Bsub168";
  my $region_ref = &run_BLAST( $query, $seq_length, $work_dir, $debug ) if ($prom_seq);

  my @prom_regions = @{ $region_ref } if ($region_ref);

# If we have a region - check that it has a unique location
  my $region;
  if ( scalar(@prom_regions) > 1) {
    warn "Sequence is not unique: $prom_seq\n";
    next;
  } else {
    $region = $prom_regions[0];
  }

# turn the region string back into its sub-parts - seems a bit clunky but hey...
  $region =~ m/(.+)\:(.+)\.\.(.+) (.+)/; 
  my ($chr, $start, $end, $strand) = ($1, $2, $3, $4) if ($region);

### If we have a unique region, make a location and sequence items 
  my ($location_item, $seq_item);
  if ($region) {
    $location_item = &make_item(
	Location => (
	  start => "$start",
	  end => "$end",
	  strand => "$strand",
	  dataSets => [$data_set_item],
	),
    );

############################################
# If we have sequence, set info for sequence item
    $seq_item = &make_item(
      Sequence => (
	'length' => $seq_length,
	residues => $prom_seq,
      ),
    );
  }

  my ($geneDBidentifier, $tfacDBidentifier, $sigmaDBidentifier);
  $geneDBidentifier = &resolver($gene_DBTBS, $region);
  next unless ($geneDBidentifier); # skip if we can't get a unique ID

  ############################################
# Set info for gene - first, check if we've seen it before
  my $gene_item = &gene_item($geneDBidentifier);

  $tfacDBidentifier = &resolver($tfac, undef) if $tfac;
  $sigmaDBidentifier = &resolver($sigma, undef) if $sigma;

# generate a unique identifier for each promoter
  my $promoter_id = $gene_DBTBS . "_" . $geneDBidentifier . "_" . $taxon_id;
  $seen_promoters{$promoter_id}++;
  
  my $promoter_uid = $promoter_id . "_" . $seen_promoters{$promoter_id};

### Process the experimental evidence
  my $refsRef = &process_refs("PromoterEvidence", \@refs, undef);
  my @evidence = @{ $refsRef };

  say "UID: $promoter_uid" if ($debug);

  my $promoter_item = &make_item(
      Promoter => (
	  primaryIdentifier => $promoter_uid,
	  chromosome => $chromosome_item,
	  dataSets => [$data_set_item],
      ),
  );

  $promoter_item->set( synonym => $synonym ) if ($synonym);
  $promoter_item->set( evidence => $refsRef ) if ($refsRef);

  if ($location_item) {
    # Add sequence and location items to promoter if applicable
    $promoter_item->set( chromosomeLocation => $location_item );
    $promoter_item->set( sequence => $seq_item );
  }

### Start adding our gene objects - gene, tfac and sigma factor
### Promoter gene items ###
  if (exists $seen_gene_items{$geneDBidentifier}) {
    $promoter_item->set( gene => $seen_gene_items{$geneDBidentifier} );
  } else {
    $promoter_item->set( gene => $gene_item );
    $seen_gene_items{$geneDBidentifier} = $gene_item;
  }

### Transcription Factor items ###
  my $tfac_item;
  if ($tfacDBidentifier) {
    unless (exists $seen_tfac_items{$tfacDBidentifier}) {
  ############################################
  # Set gene info for sigma - first, check if we've seen it before

    my $tfac_gene_item = &gene_item($tfacDBidentifier);
      unless (exists $seen_gene_items{$tfacDBidentifier}) {
	$seen_gene_items{$tfacDBidentifier} = $tfac_gene_item;
      }

############################################
# Set info for Sigma Factor - first, check if we've seen it before
      $tfac_item = &make_item(
	TranscriptionFactor => (
	    primaryIdentifier => $tfac_gene_item,
	    regulation => $regulation,
	),
      );
    }

    if (exists $seen_tfac_items{$tfacDBidentifier}) {
      $promoter_item->set( transcriptionFactor => $seen_tfac_items{$tfacDBidentifier} );
    } else {
      $promoter_item->set( transcriptionFactor => $tfac_item );
      $seen_tfac_items{$tfacDBidentifier} = $tfac_item;
    }
  }

############################################
### Sigma Factor Binding items ###

  my $sigma_item;
  if ($sigmaDBidentifier) {
    unless (exists $seen_sigma_items{$sigmaDBidentifier}) {
  ############################################
  # Set gene info for sigma - first, check if we've seen it before
    my $sigma_gene_item = &gene_item($sigmaDBidentifier);
      unless (exists $seen_gene_items{$sigmaDBidentifier}) {
	$seen_gene_items{$sigmaDBidentifier} = $sigma_gene_item;
      }

############################################
# Set info for Sigma Factor - first, check if we've seen it before
      $sigma_item = &make_item(
	  SigmaBindingFactor => (
	    primaryIdentifier => $sigma_gene_item,
	  ),
      );
    }

    if (exists $seen_sigma_items{$sigmaDBidentifier}) {
      $promoter_item->set( sigmaBindingFactors => [ $seen_sigma_items{$sigmaDBidentifier} ] );
    } else {
      $promoter_item->set( sigmaBindingFactors => [ $sigma_item ] );
      $seen_sigma_items{$sigmaDBidentifier} = $sigma_item;
    }
  }

############################################
###  Add completed promoter item to collection for genes, tfac etc
  push( @{ $seen_gene_items{$geneDBidentifier}->{'promoters'} }, $promoter_item ) if ($geneDBidentifier);
  push( @{ $seen_tfac_items{$tfacDBidentifier}->{'promoters'} }, $promoter_item ) if ($tfacDBidentifier);
  push( @{ $seen_sigma_items{$sigmaDBidentifier}->{'promoters'} }, $promoter_item ) if ($sigmaDBidentifier);

############################################

  if ($debug) {
    say OUT_FILE "\nPromoter UID: $promoter_uid";
    say OUT_FILE "	Synonym: $id" if ($id);
    say OUT_FILE "	Gene: $gene_DBTBS $geneDBidentifier";
    say OUT_FILE "	Sigma: $sigma $sigmaDBidentifier" if ($sigma);
    say OUT_FILE "	Sequence: $prom_seq" if ($prom_seq);
    say OUT_FILE "	SeqLen: $seq_length" if ($prom_seq);
    say OUT_FILE "	Region: $chr, $start, $end, $strand" if ($region);
    say OUT_FILE "	Location: $location" if ($location);
    say OUT_FILE "	Tfac: $tfac $tfacDBidentifier" if ($tfac);
    say OUT_FILE "	Reg: $regulation" if ($regulation);

    if (@evidence) {
      say OUT_FILE "	Evidence: ", join("; ", @evidence);
    }
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

  my $id = ( $entry->first_child( 'name' ) ) ? $entry->first_child( 'name' )->text : undef;
  my $operon_uid = $id . "_" . "dbtbs_" . $taxon_id;

  ############################################
# Set info for Operon
  my $operon_item = &make_item(
      Operon => (
	primaryIdentifier => $operon_uid,
	synonym => $id,
	chromosome => $chromosome_item,
	dataSets => [$data_set_item],
      ),
  );

  my $gene_operon = ( $entry->first_child( 'genes' ) ) ? $entry->first_child( 'genes' )->text : undef;
  my @operon_genes = split(',', $gene_operon);

  my @operon_gene_items;
  foreach my $operon_gene (@operon_genes) {
    my $operon_geneDBid = &resolver($operon_gene, undef);
  ############################################
# Set info for gene - first, check if we've seen it before
    my $operon_gene_item = &gene_item($operon_geneDBid);
    push(@operon_gene_items, $operon_gene_item);
  }

  $operon_item->set( genes => \@operon_gene_items );

  if ($debug) {
    say OUT_FILE "\n
      Operon => (
      primaryIdentifier => $operon_uid
      synonym => $id";
    say OUT_FILE "	genes => ", join("; ", @operon_genes);
  }

  my $experiment = ( $entry->first_child( 'experiment' ) ) ? $entry->first_child( 'experiment' )->text : undef;
  my @experiments;
  if ($experiment) {
    if ($experiment =~ m/\; /) {
      @experiments = split("; ", $experiment)
    } else {
      push(@experiments, $experiment)
    }
  }

### Process the experimental evidence
  my @refs = $entry->children( 'reference' );
  
  my $refsRef;
  if ($experiment) {
    $refsRef = &process_refs("OperonEvidence", \@refs, \@experiments);
  } else {
    $refsRef = &process_refs("OperonEvidence", \@refs, undef);
  }
  
  my @evidence;
  if ($refsRef) {
    @evidence = @{ $refsRef };
    $operon_item->set( evidence => $refsRef );
  }

  if (@evidence) {
    say OUT_FILE "	OperonEvidence: ", join("; ", @evidence);
  }

  my $comment = ( $entry->first_child( 'comment' ) ) ? $entry->first_child( 'comment' )->text : undef;
  $operon_item->set( comment => $comment ) if ($comment);

### Process terminator info
  my ($term_seq, $energy);
  my @terminators = $entry->children( 'terminator' );

  my ($terminator_item, @terminator_items, %seen_terminators);
  if (@terminators) {
    for my $terminator (@terminators) {
      $term_seq = ( $terminator->first_child( 'stemloop' ) ) ? $terminator->first_child( 'stemloop' )->text : undef;
      $energy = ( $terminator->first_child( 'energy' ) ) ? $terminator->first_child( 'energy' )->text : undef;

      my $terminator_id = "Terminator" . "_" . $operon_uid;
      $seen_terminators{$terminator_id}++;
      my $terminator_uid = $terminator_id . "_" . $seen_terminators{$terminator_id};

      $terminator_item = &make_item(
	    BacterialTerminator => (
	      primaryIdentifier => $terminator_uid,
	      energy => $energy,
	      stemloop => $term_seq,
	      dataSets => [$data_set_item],
	    ),
      );

      my $query_seq = $term_seq;
      $query_seq =~ s/\{.+?\}//g;
  #    say OUT_FILE "	TERMseq: ", $term_seq;

      my $term_query = ">$id\n$query_seq\n";
      my $seq_length = &seq_length( $query_seq ) if ($query_seq);

      say "Blasting Terminator: $id to find coordinates..." if ($debug);
      my $region_ref = &run_BLAST( $term_query, $seq_length, $work_dir, $debug ) if ($query_seq);
      my @term_regions = @{ $region_ref } if ($region_ref);

    # If we have a region - check that it has a unique location
      my $region;
      if ( scalar(@term_regions) > 1) {
	warn "Sequence is not unique: $query_seq\n";
	next;
      } else {
	$region = $term_regions[0];
      }

    # turn the region string back into its sub-parts - seems a bit clunky but hey...
      $region =~ m/(.+)\:(.+)\.\.(.+) (.+)/; 
      my ($chr, $start, $end, $strand) = ($1, $2, $3, $4) if ($region);

    ### If we have a unique region, make a location and sequence items 
      my ($location_item, $seq_item);
      if ($region) {
	$location_item = &make_item(
	    Location => (
	      start => $start,
	      end => $end,
	      strand => $strand,
	      dataSets => [$data_set_item],
	    ),
	);

    ############################################
    # If we have sequence, set info for sequence item
      $seq_item = &make_item(
	Sequence => (
	  'length' => $seq_length,
	  residues => $query_seq,
	),
      );

	$terminator_item->set( chromosomeLocation => $location_item, );
	$terminator_item->set( sequence => $seq_item, );
      }
      $terminator_item->set( operon => $operon_item, );
      push(@terminator_items, $terminator_item);

      if ($debug) {
	say OUT_FILE "
	  primaryIdentifier => $terminator_uid,
	  energy => $energy,
	  stemloop => $term_seq,
	  Location =>
	    chromosome => $chromosome,
	    start => $start,
	    end => $end,
	    strand => $strand,
	    length => $seq_length,
	    residues => $query_seq";
      }
      
    }
    $operon_item->set( terminator => \@terminator_items );
  }

  $twig->purge();
}

sub process_refs {
  my ($type, $arrRef, $experRef) = @_;

  my @refs = @{ $arrRef };

  my ($processed_ref, @processed_refs);

   foreach my $ref (@refs) {
    my $experiment = ( $ref->first_child( 'experiment' ) ) ? $ref->first_child( 'experiment' )->text : undef;
    my $pmid = ( $ref->first_child( 'pubmed' ) ) ? $ref->first_child( 'pubmed' )->text : undef;
    my $author = ( $ref->first_child( 'author' ) ) ? $ref->first_child( 'author' )->text : undef;
    my $year = ( $ref->first_child( 'year' ) ) ? $ref->first_child( 'year' )->text : undef;
    my $title = ( $ref->first_child( 'title' ) ) ? $ref->first_child( 'title' )->text : undef;
    my $genbank = ( $ref->first_child( 'genbank' ) ) ? $ref->first_child( 'genbank' )->text : undef;
    my $link = ( $ref->first_child( 'link' ) ) ? $ref->first_child( 'link' )->text : undef;

    next unless ($pmid || $title);

    # type is supplied to the subroutine and can be
    # PromoterEvidence or OperonEvidence
    my $evidence_item = &make_item(
      $type => (
      ),
    );

    # for some strange reason, dbtbs models reference evidence differently for 
    # promoters vs. operons, so we need different rules
    my ($evidenceRefs, @evidence_codes, $evidenceCode_item);

    if ($experiment) {
      # process evidence from promoters
      @evidence_codes = split(" ", $experiment); # split to get 2 letter codes
      $evidenceRefs = &evidence_lookup(\@evidence_codes); # looks up the codes to get descriptions
      # creates a collection of evidenceCode items
      $evidence_item->set( evidenceCodes => $evidenceRefs );

    } elsif ($experRef) {
      # if we have a ref to an operon 'experiment' array
      my @operon_evidenceCode_items; # array to hold evidenceCode items

      # deref array ref and loop over our evidence strings
      for my $evidence ( @{ $experRef } )  {

	say "Processing Exper: $evidence" if ($debug);

	# check hash to see whether we've already made an evidenceCode item for this exper
	if (exists $evidenceCode_items{$evidence}) {
	  say "Seen Exper before: $evidence" if ($debug);
	  my $evidenceCode_item = $evidenceCode_items{$evidence}; # if yes, use the stored evidenceCode item
	  push(@operon_evidenceCode_items, $evidenceCode_item); # add it to our evidenceCode item array
	} else {
	  # if no, make a new evidenceCode item
	  say "Haven't seen Exper before: $evidence. Making a new one" if ($debug);
	  $evidenceCode_item = &make_item(
	    OperonEvidenceCode => (
	      name => $evidence,
	    ),
	  );
	  say "Adding: $evidence to evidenceCode items array" if ($debug);
	  push(@operon_evidenceCode_items, $evidenceCode_item); # add it to our evidenceCode item array
	  $evidenceCode_items{$evidence} = $evidenceCode_item; # add new item to our evidenceCode item hash lookup
	}
      }
      say "Adding evidenceCode items array as collection to evidence item" if ($debug);
      $evidence_item->set( evidenceCodes => \@operon_evidenceCode_items );
    }

    $author =~ s/\&amp\;/and/g;
    $author =~ s/, et al\.//g;

    my ($publication_item, @publications_items);
    unless (exists $seen_ref_items{$pmid} || $seen_ref_items{$title}) {
      $publication_item = &make_item(
	Publication => (
	),
      );

      if ($pmid) {
	$publication_item->set( pubMedId => $pmid );
	$seen_publications_items{$pmid} = $publication_item;
      } else {
	$publication_item->set( firstAuthor => $author );
	$publication_item->set( title => $title );
	$publication_item->set( year => $year );
	$seen_publications_items{$title} = $publication_item;
      }
      push(@publications_items, $publication_item);
      
    }
  
  #### PLAYED AROUND WITH THIS SECTION - problems as promoters and operons handle references differently
  ### Promoters: multiple evidence codes per publication
  ### Operons: independent but multiple publications per evidence code
    $evidence_item->set( publications => \@publications_items, );

    if ($pmid) {
      if (exists $seen_ref_items{$pmid}) {
	say "Already seen pmid: $pmid. Reusing..." if ($debug);
	$processed_ref = $seen_ref_items{$pmid};
      } else {
	$processed_ref = $evidence_item;
	$seen_ref_items{$pmid} = $evidence_item;
      }
    } elsif ($title) {
      if (exists $seen_ref_items{$title}) {
	say "Already seen title: $title. Reusing..." if ($debug);
	$processed_ref = $seen_ref_items{$title};
      } else {
	$processed_ref = $evidence_item;
	$seen_ref_items{$title} = $evidence_item;
      }
    } 
    push(@processed_refs, $processed_ref);

  }

  if (@processed_refs) {
    \@processed_refs;
  } else { return; }

}


sub seq_length {
  my $in = shift;
  my $length = length($in);
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

sub gene_lookup {

  my ($gene_DBTBS, $region) = @_;

  my ($synbioRef, @identifiers);
  if ( exists $seen_genes{$gene_DBTBS} ) {
    warn "Already seen gene: $gene_DBTBS. Reusing resolved ID...\n" if ($debug);
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
	warn "Problem: Symbols don't match: $symbol eq $symbol2check - can't resolve $identifier\n" if ($debug);
#	push (@identifiers, $identifier);
      }
      else {
	warn "Ouch: $id not found in synbiomine!\n" if ($debug);
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

sub evidence_lookup {
  
  my $evidenceRef = shift;
  my @evidence_codes = @{ $evidenceRef };

## use a heredoc to hold formatted list
# then use to poplulate a hash based on a simple RE

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
    say OUT_FILE "Code: ", $code if ($debug);
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
