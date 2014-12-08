#!/usr/bin/env perl
# -*-Perl-*-

use File::Basename;
use LibSBML;
use Getopt::Std;
use strict;
use warnings;

use feature ':5.12';

use InterMine::Item::Document;
use InterMine::Model;

# Print unicode to standard out
binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

my $usage = "usage: @{[basename($0)]} reactions_files.sbml taxonId intermine_model_file

Script to process EBI's path2model whole genome reactions file
Writes an items XML with reaction, pathways & gene mappings

# Options
-v\tverbose output

\n";

### command line options ###
my (%opts, $verbose);

getopts('hv', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"v"} and $verbose++;

# specify and open query file (format: )
my ($reactions_file, $taxon_id, $model_file) = @ARGV;
unless ( $ARGV[2] ) { die $usage };

say "Reading \"$reactions_file\"" if ($verbose);

my $data_source_name = "Biomodels Database";
my $source_url = "http://www.ebi.ac.uk/biomodels-main";

# instantiate the model
my $im_model = new InterMine::Model(file => $model_file);
my $doc = new InterMine::Item::Document(model => $im_model);

my $org_item = make_item(
    Organism => (
        taxonId => $taxon_id,
    )
);

my $data_source_item = make_item(
    DataSource => (
        name => $data_source_name,
	url => $source_url,
    ),
);

my $reactions_data_set_item = make_item(
    DataSet => (
        name => "path2models for taxonId $taxon_id",
	dataSource => $data_source_item,
    ),
);

my $rd = new LibSBML::SBMLReader();
my $d  = $rd->readSBML($reactions_file);

$d->printErrors();

our $model = $d->getModel();
#printAnnotation($model);

my (%species_identifiers);
my (%seen_genes, %seen_gene_items);
my (%seen_compound_items);

my $type_note = "isSetNotes";
my $type_annotation = "isSetAnnotation";

foreach my $spec ($model->getListOfSpecies()) {
  my $sboterm = $spec->getSBOTerm();
  my $species_name = $spec->getName();
  my $charge = $spec->getCharge();

  if ( ($sboterm) && ($sboterm eq "252") ) {
    say "GeneRef: ", $spec->getId(), "  - skipping..."  if ($verbose);
# #     my ($pid_annot, $annot_sb) = &process_element($type_annotation, $spec);
# #     say "PID annot: ", $pid_annot if ($verbose);
# # 
# #     $pid_annot =~ /(.+)_[a-z]+/;
# #     my $gene_id = $1;
# # 
# #     say "GeneId: $gene_id" if ($verbose);
# # 
# #     $seen_genes{$pid_annot}++;
# #     &make_gene_item($gene_id);
    next;

  } else {

  say "Processing species with Name: ", $spec->getName() if ($verbose);
    my $species_id = $spec->getId();
    $species_identifiers{$species_id}->{'sboterm'} = "0000$sboterm";
    $species_identifiers{$species_id}->{'name'} = $species_name;
    $species_identifiers{$species_id}->{'charge'} = $charge;

    my ($pid_note, $note_sb) = &process_element($type_note, $spec);
#    say "PID note: ", $pid_note if ($pid_note);

    &extract_species_IDs($pid_note, $note_sb) if ($pid_note);

    my ($pid_annot, $annot_sb) = &process_element($type_annotation, $spec);
#    say "PID annot: ", $pid_annot if ($pid_annot);

    if (! $pid_annot) {

      next if ($species_id =~ /biomass_bm/);

      $species_id =~ /^(.+)_[a-z]+/;
      my $fallback_id = $1;

      $fallback_id =~ s/^bigg_/BIGG:/ if ($fallback_id =~ /^bigg_/);
      $fallback_id =~ s/^/MNXREF:/ if ($fallback_id =~ /MNX/);

      say "NO CHEBI - falling back to $fallback_id" if ($verbose);
      $species_identifiers{$species_id}->{'identifier'} = $fallback_id;

      next;
    } else {
      &extract_CHEBI($pid_annot, $annot_sb);
    }
  }
}

if ($verbose) {
  say "_**_";
  for my $key (keys %species_identifiers) {
    for my $db (keys %{ $species_identifiers{$key} } ){
      say "Key: ", $key, " Db: ", $db, " val: ", $species_identifiers{$key}->{$db};
    }
  }
  say "*__*";
}

# # say
# #     "Species: ",
# #     join(", ", map{$_->getId()} $model->getListOfSpecies()), "\n";

# "Reaction with Id ", $reaction->getId(), "\nhas ",

for my $reaction ($model->getListOfReactions()) {

  say "Processing reaction with Name: ", $reaction->getName() if ($verbose);

  my $modifCheck = $reaction->getNumModifiers();
  next unless ($modifCheck);

  my $sboterm = $reaction->getSBOTerm();

# get KEGG reaction ids
  my $annot = $reaction->getAnnotationString();
  my @arr = split('\n', $annot);
  my @kegg = grep (/reaction/, @arr);
  
  # make a reaction item for each KEGG reaction
  my @reaction_species_items;
  for my $url (@kegg) {
    $url =~ /.+:(R.+)\".+/;
    my $kegg_reaction = $1;

    my $reaction_item = make_item(
      Reaction => (
	  identifier => $kegg_reaction,
	  type => "biochemical reaction",
	  sboterm => "0000$sboterm",
	  dataSets => [ $reactions_data_set_item ],
      ),
    );

# process Reactants and Products and push resulting ReactionSpecies items
# into an array to plug in to the Reaction item we're making
    my $reactantsRefs = &process_reaction_species("Reactants", $reaction);
    @reaction_species_items = @{ $reactantsRefs };
    my $productsRefs = &process_reaction_species("Products", $reaction);
    push(@reaction_species_items, @{ $productsRefs });
    $reaction_item->set( reactionSpecies => \@reaction_species_items, );

# Now process the modifiers and add to the Reaction item 
    my $gene_items_ref = &process_modifiers($reaction);
    $reaction_item->set( modifiers => $gene_items_ref, );

# Now process kinetic parameters and add to the Reaction item 
    my $paremetersRef = &process_parameters($reaction);
    $reaction_item->set( kineticParameters => $paremetersRef, ) if ($paremetersRef);

    say "kegg: $kegg_reaction" if ($verbose);
  }

 say "*_*\n" if ($verbose);

}

$doc->close(); # writes the xml
exit(0);

### Subroutines ###

sub process_element {

  my ($type, @elRef) = @_;
  my $sb = $elRef[0];
#  my $id = defined $_[1] ? $_[1] : '';

  if (not $sb->$type()) {
	return;        
  }

  my $pid = "";  
  if ($sb->isSetId()) {
      $pid = $sb->getId();
  }
  return ($pid, $sb);
}

sub extract_species_IDs {
  
  my ($pid, $sb) = @_;
  unless ($sb) { 
    say "Err: No sb for $pid in note" if ($verbose);
    return };     

  my $note_string = $sb->getNotesString();
  unless ($note_string) { return };

  open my ($note_fh), '+<', \$note_string; # process 

  while (<$note_fh>) {
    chomp;
    return if ($_ =~ m|</body>|);
    next if ($_ =~ /notes/);
    next if ($_ =~ /body/);

#    say "LINE: ", $_  if ($verbose);

    $_ =~ s/^\s+//;
    $_ =~ s/<.?p>//g;

    my $match = $_ =~ /(.+): (.+)/;
    next unless ($match);

    my ($database, $value_string) = ($1, $2);

    if ( ($database =~ /FORMULA/) and ($value_string) ) {
      $species_identifiers{$pid}->{'formula'} = $value_string;
    }
  }
  close ($note_fh);
}

sub extract_CHEBI {
  
  my ($pid, $sb) = @_;
  unless ($sb) { return };

  my $annot_string = $sb->getAnnotationString();

  my @arr = split('\n', $annot_string);
  my @chebi_raw = grep (/CHEBI/, @arr);

  my $first_chebi = $chebi_raw[0];
  $first_chebi =~ s/^.+urn:miriam:chebi:CHEBI%3A//;
  $first_chebi =~ s/\".+$//;

  $species_identifiers{$pid}->{'identifier'} = "CHEBI:$first_chebi";

  say "CHEBI: ", $first_chebi if ($verbose);

# #   my @chebi_processed;
# #   for my $entry_raw (@chebi_raw) {
# #     $entry_raw =~ /.+3A(.+)\".+/;
# #     my $chebi =~ $1;
# #     push (@chebi_processed, $chebi);
# # 
# # #    say "CHEBI: ", $chebi if ($verbose);
# #   }
#  $species_identifiers{$pid}->{'CHEBI'} = \@chebi_processed;
}

sub process_reaction_species {
  
  my ($type, $objects) = @_;

  my $role = ($type =~ /Reactants/) ? "input" : "output";

  my $getList = "getListOf$type";

  # process reaction species
  my @species = $objects->$getList();

  my ($compound_item, @compound_items, @reaction_species_items);
  for my $element (@species) {
    my $entity = $element->getSpecies();
    my $stoichiometry = $element->getStoichiometry();

    my $reactionSpecies_item = make_item(
	ReactionSpecies => (
	    stoichiometry => $stoichiometry,
	    role => $role,
	),
    );

    if ( exists $species_identifiers{$entity} ) {
      say "$type: ", $entity, " Identifier:- ", $species_identifiers{$entity}->{'identifier'} if ($verbose)
;
      my $compound_item = &make_compound_item($entity);
      $reactionSpecies_item->set( compound => $compound_item, );
      push(@reaction_species_items, $reactionSpecies_item);

    } else {
      say "Oops - can't find $type $entity in identifier look-up";
    }
  }
  return \@reaction_species_items;
}

sub process_modifiers {
  
  my ($objects) = shift;

  # process modifiers
  my @modifiers = $objects->getListOfModifiers();

  my @gene_items;
  for my $modifier (@modifiers) {
    my $id = $modifier->getSpecies();
    next if ($id =~ /_2_[a-z]+$/);
    $id =~ /^(.+)_.+/;
    my $gene = $1;

    my $gene_item;
    if (exists $seen_gene_items{$gene}) {
      say "Seen gene $gene - reusing gene item" if ($verbose);
      $gene_item = $seen_gene_items{$gene};
    } else {
      $gene_item = make_item(
	  Gene => (
	      primaryIdentifier => $gene,
	  ),
      );
      $seen_gene_items{$gene} = $gene_item;
    }
    push(@gene_items, $gene_item);
  }
  return \@gene_items;
}

sub process_parameters {
  
  my $objects = shift;

  my (@parameters, %parameter_pairs);
  if ($objects->isSetKineticLaw()) {
    my $kl = $objects->getKineticLaw();
    @parameters = $kl->getListOfParameters();
  } else {
    return;
  }

  my $parameter_item = make_item(
	KineticParameters => (
	    type => "flux balance",
	),
  );

  for my $parameter (@parameters) {
    my $id = $parameter->getId();
    my $value = $parameter->getValue();

    $parameter_pairs{'upperBound'} = $value if ($id =~ /^UPPER_BOUND/);
    $parameter_pairs{'lowerBound'} = $value if ($id =~ /^LOWER_BOUND/);
    $parameter_pairs{'fluxValue'} = $value if ($id =~ /^FLUX_VALUE/);
    $parameter_pairs{'objectiveCoefficient'} = $value if ($id =~ /^OBJECTIVE_COEFFICIENT/);

    say "Parameters: $id has value $value" if ($verbose);
  }

  for my $key (keys %parameter_pairs) {
    say "Params:  $key => $parameter_pairs{$key}" if ($verbose);
    $parameter_item->set( $key => $parameter_pairs{$key}, );
  }
  return $parameter_item;
}

######## helper subroutines:

sub make_gene_item {
  my $id = shift;

  my $gene_item;
  if (exists $seen_gene_items{$id}) {
    say "Seen gene $id - reusing gene item" if ($verbose);
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

sub make_compound_item {
  my $id = shift;

  my $compound_id = $species_identifiers{$id}->{'identifier'};

  my $compound_item;
  if (exists $seen_compound_items{$id}) {
    say "Seen compound $id - reusing compound item" if ($verbose);
    $compound_item = $seen_compound_items{$id};
  } else {

    my $name = $species_identifiers{$id}->{'name'};
    my $formula = $species_identifiers{$id}->{'formula'};
    my $charge = $species_identifiers{$id}->{'charge'};
    my $sboterm = $species_identifiers{$id}->{'sboterm'};

    $compound_item = make_item(
	Compound => (
	    identifier => $compound_id,
	    sboterm => $sboterm,
	),
    );

    $compound_item->set( charge => $charge, ) if ($charge);
    $compound_item->set( formula => $formula, ) if ($formula);

    $seen_compound_items{$id} = $compound_item;
  }
  return $compound_item;
}

sub make_item {
    my @args = @_;
    my $item = $doc->add_item(@args);
    if ($item->valid_field('organism')) {
        $item->set(organism => $org_item);
    }
    return $item;
}


# # sub printAnnotation {
# #   my ($pid, $sb) = @_;
# # 
# #   my $annot = $sb->getAnnotationString();
# #   my @arr = split('\n', $annot);
# # 
# #   print("----- ", $sb->getElementName(), " (", $pid, ") annotation -----", "\n");
# #   print($sb->getAnnotationString(), "\n");
# #   print("\n");
# # }
# # 
# # sub printNotes {
# # 
# #   my ($pid, $sb) = @_;
# # 
# #   print("----- ", $sb->getElementName(), " (", $pid, ") notes -----", "\n");
# #   print($sb->getNotesString(), "\n");
# #   print("\n");
# # }

# # # process reactants
# #   my @reactants = $reaction->getListOfReactants();
# # 
# #   for my $reactant (@reactants) {
# #     my $a = $reactant->getSpecies();
# #     if ( exists $species_identifiers{$a}->{'CHEBI'} ) {
# #       say "Spec: ", $a, " CHEBI:- ", join("; ", @{ $species_identifiers{$a}->{'CHEBI'} } );
# # 
# #     }
# #   }
  
  # process products
#   my @products = $reaction->getListOfProducts();
# 
#   for my $product (@products) {
#     my $a = $product->getSpecies();
# #     if ( exists $species_identifiers{$a}->{'CHEBI'} ) {
#       say "Spec: ", $a, " CHEBI:- ", join("; ", @{ $species_identifiers{$a}->{'CHEBI'} } );
# 
#     }
#   }
  
  
#  printAnnotation($reaction);
#  my $type = "isSetAnnotation";
#  my ($pid, $sb) = &process_element($type, $reaction);
#  &extract_species_IDs($pid, $sb);
#  say "*_*";
#  &printNotes($pid, $sb);
#  say "*_* *_*";
#  &printAnnotation($pid, $sb);


# #   say
# #       "Reaction with Name ", $reaction->getName(), "\nhas ",
# #       $reaction->getNumReactants(), " Reactant(s), ",
# #       $reaction->getNumProducts(), " Product(s), ",      
# #       $reaction->getNumModifiers(), " Modifier(s)\n",       
# #       "Reactant(s): ",
# #       join(", ", map{$_->getSpecies()} $reaction->getListOfReactants()), "\n",
# #       "Product(s): ",
# #       join(", ", map{$_->getSpecies()} $reaction->getListOfProducts()), "\n",
# #       "Modifier(s): ",
# #       join(", ", map{$_->getSpecies()} $reaction->getListOfModifiers()),"\n";
# # 


__END__
