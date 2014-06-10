#!/usr/bin/perl

use strict;
use warnings;
use LWP::Simple;
use XML::Twig;

# start timer
my $start = time();

my $blast_results_file = $ARGV[0];    #FASTA
my $out_file = $ARGV[1];

#$uniprot_file = $ARGV[1];

open IN, "$blast_results_file" or die "can't open file";
open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";

my %topHit = ();

while (<IN>) {
   chomp $_;
   my @split = split( /\t/, $_ );
   $split[0] =~ /^(Locus_\d+)_Tran/;
   my $evalue = $split[10];
   my $locus  = $1;

   #print "$split[1]\n";
   $split[1] =~ /\|\S+\|[^_]+_([^:]+)/;
   my $orgm = $1;
   $split[1] =~ /\|(\S+)\|/;
   my $accession = $1;

    if ( (exists $topHit{$locus}) && ($evalue > $topHit{$locus}->[0]) ) {
      #print "$locus\t$orgm\t$evalue\t$accession ", $evalue, " is gt ", $topHit{$locus}->[0], "\n";
      next;
    } else {
      $topHit{$locus} = [$evalue, $accession, $orgm];
    }

}

close IN;

foreach my $entry ( keys %topHit ) {
  my $eval = "$topHit{$entry}->[0]";
  my $acc = "$topHit{$entry}->[1]";
  my $spec = "$topHit{$entry}->[2]";

  next unless ($eval < 0.00001);
    #print $entry, "\t", join("\t", @{ $topHit{$entry} } ), "\n";
  print OUT_FILE $entry, "\t", $acc, "\_", $spec, "\_", $eval, "\t";

  my $twig = new XML::Twig( twig_handlers => 
			  { 
					     protein => \&prot_name,
					     'entry/dbReference' => \&dbRef
			  }  
  ); 

  my $protXMLdir = "/home/ml590/sdata/adrian_shared_files/uniprot_cache/";
  my $protFile = "$acc.xml";
  my $fileCheck = "$protXMLdir$protFile";

  if (-e "$fileCheck") {
    print "File $fileCheck exists.\n"; 
    $twig->parsefile($fileCheck);
    $twig->purge;
    print OUT_FILE "\n";

  } else {
    print "No File: $fileCheck. Retrieving...\n";
    my $response = getXML(\$protFile);
      $twig->parse($response);
      $twig->purge;

      print OUT_FILE "\n";
  }
  
#print "ID: $acc: ";

#  my $base = "http://www.uniprot.org/uniprot/";
#  my $query = "$acc.xml";
#  my $url = "$base$query";
#  print "\n", $url, "\n";
#  my $email = "&email=mike\@intermine.org";

#   my $agent    = LWP::UserAgent->new;
#   my $request  = HTTP::Request->new(GET => $url);
#   my $response = $agent->request($request);
#   $response->is_success or print "$entry\tError: " . 
#   $response->code . " " . $response->message, "\n";
#  print $response->content, "\n";

#  my $response = get($url);

# the prot_name and dbRef function will be called every time a protein element is processed

#  $twig->parse($uniprot_result);
##  $twig->parse($response);
##  $twig->purge;

##  print "\n";

#print $upEntry, "\n";
}

close OUT_FILE;

sub getXML {
  my $accRef = shift;
  my $acc = $$accRef;
  my $base = "http://www.uniprot.org/uniprot/";
  my $query = "$acc.xml";
  my $url = "$base$query";

#  my $response = get($url);
  get($url);
}

sub prot_name {
  my ($twig, $prot) = @_; # twig is the whole twig; prot is the element being processed
  print OUT_FILE $prot->first_descendant('fullName')->text, "\t";
  $twig->purge
}

sub dbRef {
  my ($twig, $elt)= @_;

#  my (@GO, @PFAM);

  if ($elt->att('type') eq 'ZFIN') {
    print OUT_FILE $elt->att('id'), "\t";
#    print $elt->first_descendant('property')->att('value'), "; ";
  } 

  if ($elt->att('type') eq 'Pfam') {
    print OUT_FILE $elt->att('id'), "-";
    if (my $geneName = $elt->first_descendant('property') ) {
      print OUT_FILE $elt->first_descendant('property')->att('value'), "; ";
    }
  }

  if ($elt->att('type') eq 'GO') {
    print OUT_FILE $elt->att('id'), "-";
    print OUT_FILE $elt->first_descendant('property')->att('value'), "; ";
  }

  $twig->purge;
}

