#!/usr/bin/env perl
# -*-Perl-*-

use File::Basename;
use LibSBML;
use strict;
use warnings;
use Data::Dumper;

use feature ':5.12';

my $filename = shift()
    || do { printf STDERR "\n  usage: @{[basename($0)]} <filename>\n\n";
            exit (1);
          };

print "Reading \"$filename\"\n";

my $rd = new LibSBML::SBMLReader();
my $d  = $rd->readSBML($filename);

$d->printErrors();

our $model = $d->getModel();
#printAnnotation($model);

my (%species_identifiers, %seen_genes);

#say "\nUsing Method getListOfXXXX in list context!!!\n";

my $type_note = "isSetNotes";
my $type_annotation = "isSetAnnotation";

foreach my $spec ($model->getListOfSpecies()) {
  my $sboTerm = $spec->getSBOTerm();
#  say "Species with SBO ", $spec->getSBOTerm();
#  say "Species with Name ", $spec->getId();

  if ( ($sboTerm) && ($sboTerm eq "252") ) {
#    say "Gene: ", $spec->getId();
    my ($pid_annot, $annot_sb) = &process_element($type_annotation, $spec);
#    say "PID annot: ", $pid_annot;
    $seen_genes{$pid_annot}++;
    next;
  } else {

#  say "Species with Name ", $spec->getName();

    my ($pid_note, $note_sb) = &process_element($type_note, $spec);
#    say "PID note: ", $pid_note if ($pid_note);

    &extract_species_IDs($pid_note, $note_sb) if ($pid_note);

    my ($pid_annot, $annot_sb) = &process_element($type_annotation, $spec);
#    say "PID annot: ", $pid_annot if ($pid_annot);

    if (! $pid_annot) {

      my $species_id = $spec->getId();
      next if ($species_id =~ /biomass_bm/);

      $species_id =~ /(.+)_[a-z]+/;
      my $fallback_id = $1;

      $fallback_id =~ s/^bigg_/BIGG:/ if ($fallback_id =~ /^bigg_/);
      $fallback_id =~ s/^/MNXREF:/ if ($fallback_id =~ /MNX/);

#      say "NO CHEBI - falling back to $fallback_id";
      $species_identifiers{$species_id}->{'identifier'} = $fallback_id;
      next;
    }

    &extract_CHEBI($pid_annot, $annot_sb) if ($pid_annot);
  }

}

# # for my $key (keys %species_identifiers) {
# #   for my $db (keys %{ $species_identifiers{$key} } ){
# #     say "Key: ", $key, " Db: ", $db;
# #   }
# # }

# # say
# #     "Species: ",
# #     join(", ", map{$_->getId()} $model->getListOfSpecies()), "\n";

# "Reaction with Id ", $reaction->getId(), "\nhas ",

for my $reaction ($model->getListOfReactions()) {
  say "Reaction with Name ", $reaction->getName(), "\n";

  &process_species("Reactants", $reaction);
  &process_species("Products", $reaction);
  &process_modifiers($reaction);
  &process_parameters($reaction);
  
  my $annot = $reaction->getAnnotationString();
  my @arr = split('\n', $annot);
  my @kegg = grep (/reaction/, @arr);
  
  for my $el (@kegg) {
    $el =~ s/.+miriam://g;
#    $el =~ s/CHEBI\%3A//g;
    $el =~ s/\"\/>//g;
    say "el: $el";
  }
 say "*_*\n";

}

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
#    say "Err: No sb for $pid in note";
    return };     

  my $note_string = $sb->getNotesString();
  unless ($note_string) { return };

  open my ($note_fh), '+<', \$note_string; # process 

  while (<$note_fh>) {
    chomp;
    return if ($_ =~ m|</body>|);
    next if ($_ =~ /notes/);
    next if ($_ =~ /body/);

#    say "LINE: ", $_;

    $_ =~ s/^\s+//;
    $_ =~ s/<.?p>//;

    my $match = $_ =~ /(.+): (.+)/;
    next unless ($match);

    my ($database, $value_string) = ($1, $2);

    if ($database =~ /FORMULA/) {
      $species_identifiers{$pid}->{'formula'} = $value_string;
    } elsif ($database =~ /CHARGE/) {
      $species_identifiers{$pid}->{'charge'} = $value_string;
    }
  }

  close ($note_fh);
#  say "NOTES: \n", "$database:- ", join("; ", @values);
  
}

sub extract_CHEBI {
  
  my ($pid, $sb) = @_;
  unless ($sb) { return };

#  $pid =~ /(.+)_[a-z]+/;
#  my $fallback_id= $1;

#  if (not defined $sb)  {
#    say "NO CHEBI - falling back to $fallback_id";
#    $species_identifiers{$pid}->{'identifier'} = $fallback_id;
#    return;
#  }

  my $annot_string = $sb->getAnnotationString();

  my @arr = split('\n', $annot_string);
  my @chebi_raw = grep (/CHEBI/, @arr);

  my $first_chebi = $chebi_raw[0];

  $first_chebi =~ s/.+://g;
  $first_chebi =~ s/CHEBI\%3A//g;
  $first_chebi =~ s/\"\/>//g;

# #   my @chebi_processed;
# #   for my $entry (@chebi_raw) {
# # 
# #     $entry =~ s/.+://g;
# #     $entry =~ s/CHEBI\%3A//g;
# #     $entry =~ s/\"\/>//g;
# # 
# #     push (@chebi_processed, $entry);
# # 
# # #    say "CHEBI: ", $entry;
# #   }
#  $species_identifiers{$pid}->{'CHEBI'} = \@chebi_processed;
  $species_identifiers{$pid}->{'identifier'} = "CHEBI:$first_chebi";
}

sub process_species {
  
  my ($type, $objects) = @_;
  my $getList = "getListOf$type";
  # process reactants
  my @species = $objects->$getList();

  for my $element (@species) {
    my $entity = $element->getSpecies();
    if ( exists $species_identifiers{$entity}->{'identifier'} ) {
      say "$type: ", $entity, " Identifier:- ", $species_identifiers{$entity}->{'identifier'};
#      say "$type: ", $entity, " CHEBI:- ", join("; ", @{ $species_identifiers{$entity}->{'CHEBI'} } );
#      say "Name: ", join("; ", @{ $species_identifiers{$entity}->{'BIOPATH'} } );
    } else {
      say "Oops - can't find $type $entity in identifier look-up";
    }
  }
}

sub process_modifiers {
  
  my ($objects) = shift;

  # process modifiers
  my @modifiers = $objects->getListOfModifiers();

  for my $modifier (@modifiers) {
    my $gene = $modifier->getSpecies();
    if ( exists $seen_genes{$gene} ) {
      say "Seen Gene: $gene - before";
    } else {
      say "Oops - can't find $gene in look-up";
    }
  }
}

sub process_parameters {
  
  my $objects = shift;

  my @parameters;
  if ($objects->isSetKineticLaw()) {
    my $kl = $objects->getKineticLaw();
    @parameters = $kl->getListOfParameters();
  }

  for my $parameter (@parameters) {
    my $id = $parameter->getId();
    my $value = $parameter->getValue();

    say "Params: $id has value $value";
  }
}

sub printAnnotation {
  my ($pid, $sb) = @_;

  my $annot = $sb->getAnnotationString();
  my @arr = split('\n', $annot);

  print("----- ", $sb->getElementName(), " (", $pid, ") annotation -----", "\n");
  print($sb->getAnnotationString(), "\n");
  print("\n");
}

sub printNotes {

  my ($pid, $sb) = @_;

  print("----- ", $sb->getElementName(), " (", $pid, ") notes -----", "\n");
  print($sb->getNotesString(), "\n");
  print("\n");
}

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
