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

my %species_identifiers;

say "\nUsing Method getListOfXXXX in list context!!!\n";

foreach my $spec ($model->getListOfSpecies()) {

  my $type_note = "isSetNotes";
  my $type_annotation = "isSetAnnotation";
  my ($pid_note, $note_sb) = &process_element($type_note, $spec);
  my ($pid_annot, $annot_sb) = &process_element($type_annotation, $spec);
  &extract_IDs($pid_note, $note_sb);
#  &printNotes($pid, $sb);
#  &printAnnotation($pid_annot, $annot_sb);
  &extract_CHEBI($pid_annot, $annot_sb);

}

# # say
# #     "Species: ",
# #     join(", ", map{$_->getId()} $model->getListOfSpecies()), "\n";

# "Reaction with Id ", $reaction->getId(), "\nhas ",

for my $reaction ($model->getListOfReactions()) {

# get list of reactants
  my @reactants = $reaction->getListOfReactants();

  for my $reactant (@reactants) {
    # extract reactants species and look up identifiers
    my $a = $reactant->getSpecies();
    if ( exists $species_identifiers{$a}->{'CHEBI'} ) {
      say "Spec: ", $a, " CHEBI:- ", join("; ", @{ $species_identifiers{$a}->{'CHEBI'} } );

    }
  }
#  printAnnotation($reaction);
#  my $type = "isSetAnnotation";
#  my ($pid, $sb) = &process_element($type, $reaction);
#  &extract_IDs($pid, $sb);
#  say "*_*";
#  &printNotes($pid, $sb);
#  say "*_* *_*";
#  &printAnnotation($pid, $sb);

  my $annot = $reaction->getAnnotationString();
  my @arr = split('\n', $annot);
  my @kegg = grep (/reaction/, @arr);

  say
      "Reaction with Name ", $reaction->getName(), "\nhas ",
      $reaction->getNumReactants(), " Reactant(s), ",
      $reaction->getNumProducts(), " Product(s), ",      
      $reaction->getNumModifiers(), " Modifier(s)\n",       
      "Reactant(s): ",
      join(", ", map{$_->getSpecies()} $reaction->getListOfReactants()), "\n",
      "Product(s): ",
      join(", ", map{$_->getSpecies()} $reaction->getListOfProducts()), "\n",
      "Modifier(s): ",
      join(", ", map{$_->getSpecies()} $reaction->getListOfModifiers()),"\n";

  for my $el (@kegg) {
    say "el: $el";
  }
 say "\n";
}

### Subroutines ###

sub process_element {

  my ($type, @elRef) = @_;

  my $sb = $elRef[0];
#  my $id = defined $_[1] ? $_[1] : '';

#  if (not $sb->isSetAnnotation()) {
#	return;        
#  }

  if (not $sb->$type()) {
	return;        
  }

  my $pid = "";
  
  if ($sb->isSetId()) {
      $pid = $sb->getId();
  }

  return ($pid, $sb);

}

sub extract_IDs {
  
  my ($pid, $sb) = @_;
  unless ($sb) { return };     

  my $note_string = $sb->getNotesString();
  $note_string =~ s/^\s+//smg;
  $note_string =~ s/<.?p>//smg;

  my @notes = split("\n", $note_string);
  my @databases = grep (/:/ && !/http/, @notes);

  for my $source (@databases) {
    $source =~ /(.+): (.+)/;
    my ($database, $value_string) = ($1, $2);
    next if ($database =~ /CHEBI/);
    my @values = split(", ", $value_string);
#    say "$database:- ", join("; ", @values);
    $species_identifiers{$pid}->{$database} = \@values;
  }

#  say "NOTES: \n", "$database:- ", join("; ", @values);
  
}

sub extract_CHEBI {
  
  my ($pid, $sb) = @_;
  unless ($sb) { return };     

  my $annot_string = $sb->getAnnotationString();

  my @arr = split('\n', $annot_string);
  my @chebi_raw = grep (/CHEBI/, @arr);

  my @chebi_processed;
  for my $entry (@chebi_raw) {

    $entry =~ s/.+://g;
    $entry =~ s/CHEBI\%3A//g;
    $entry =~ s/\"\/>//g;

    push (@chebi_processed, $entry);

#    say "CHEBI: ", $entry;
  }
  $species_identifiers{$pid}->{'CHEBI'} = \@chebi_processed;
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


__END__
