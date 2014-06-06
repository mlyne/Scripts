#!/usr/local/bin/perl -w

use strict;
use Getopt::Std;

# $Header: /nfs/disk222/yeastpub/Repository/zoo/general/exblx_to_tab.pl,v 1.5 1999/11/16 15:04:25 kmr Exp $

# purpose: This script will convert the output from MSPcrunch -x into tab file
# purpose: format.  Hits to the same protein will be collected together with a
# purpose: join ().

my $min_score = -999;

sub usage
{
  die <<EOF;
usage: $0 -h (for help)
       $0 [-m min_score] [-k output_key]
EOF
}

if (!@ARGV || ($ARGV[0] eq "-h")) {
  usage;
}

my %options = ();

getopt ("m:k:", \%options);

if (exists $options{'m'}) {
  $min_score = $options{'m'};

  if ($min_score !~ /^[\d\.]+$/) {
    die "$0: the -m option need a numeric argument\n";
  }
}

my $output_key = "BLASTCDS";

if (exists $options{k}) {
  $output_key = $options{k};
}

sub print_group
{
  my ($note_field, $complement_flag, @hit_array) = @_;

  if (@hit_array == 0) {
    return;
  }

  # sort the hit into left-right order
  @hit_array = sort {
    $a->{start} <=> $b->{start}
  } @hit_array;

  my $max_score = -99999;

  if (
      (grep { 
        if ($_->{score} > $max_score) {
          $max_score = $_->{score};
        }
        $_->{score} > $min_score
      } @hit_array) == 0) {
    print STDERR "no hits > $min_score for:\n  $note_field\n";
    return;
  }

  my $location = "";

  if ($complement_flag) {
    $location .= "complement(";
  }

  if (@hit_array > 1) {
    $location .= "join(";
  }

  my @location_bits = ();

  for my $hit (@hit_array) {
    push @location_bits, $hit->{start} . ".." . $hit->{stop};
  }

  $location .= join ",", @location_bits;
  
  if (@hit_array > 1) {
    $location .= ")";
  }

  if ($complement_flag) {
    $location .= ")";
  }

  my $small_score = int($max_score/10);

  $note_field =~ s/\"/""/g;

  printf "FT   %-15.15s $location\n", $output_key;
  print "FT                   /note=\"max score = $max_score  $note_field\"\n";
  print "FT                   /score=$small_score\n";

  my $colour_index = $small_score;

  if ($colour_index > 99) {
    $colour_index = 99;
  }

  my $colour = (17,16,15,2)[$colour_index / 25];
  
  print "FT                   /colour=$colour\n";

  for my $hit (@hit_array) {
    my $hit_score = $hit->{score};
    my $start = $hit->{start};
    my $end = $hit->{stop};

    my $protein_start = $hit->{protein_start};
    my $protein_stop = $hit->{protein_stop};

    if ($complement_flag) {
      my $note = "score = $hit_score  protein: $protein_start..$protein_stop  at complement($start..$end)";
      print "FT                   /note=\"$note\"\n";
    } else {
      my $note = "score = $hit_score  protein: $protein_start..$protein_stop  at $start..$end";
      print "FT                   /note=\"$note\"\n";
    }
  }
}

sub print_hits
{
  my ($note_field, @hit_array) = @_;

  my @forward_strand_hits = grep { ! $_->{complement_flag} } @hit_array;
  my @reverse_strand_hits = grep { $_->{complement_flag} }   @hit_array;

  print_group $note_field, 1, @reverse_strand_hits;
  print_group $note_field, 0, @forward_strand_hits;
}

my %hit_hash = ();

while (<>) {    

  if (/(\d+)\s+\((.)\S+\)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(.*)/) {
    my ($score, $frame, $start, $stop, $protein_start, $protein_stop, $note) =
      ($1, $2, $3, $4, $5, $6, $7);
    
    my $complement_flag = 0;

    if ($frame eq '-') {
      $complement_flag = 1;
    } else {
      $complement_flag = 0;
    }

    if (! exists $hit_hash{$note}) {
      $hit_hash{$note} = [];
    }

    my $array_ref = $hit_hash{$note};

    push @$array_ref, {
      score => $score,
      complement_flag => $complement_flag,
      start => $start,
      stop => $stop,
      protein_start => $protein_start,
      protein_stop => $protein_stop
    };
  } else {
    die "error reading while reading MSPcrunch output:\n   $_\n";
  }
}

for my $hash_key (keys %hit_hash) {
  my @hit_array = @{$hit_hash{$hash_key}};
  print_hits $hash_key, @hit_array;
}
