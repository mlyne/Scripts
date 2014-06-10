#!/usr/bin/perl

use strict;
use warnings;
use LWP::Simple;
use XML::Twig;

# start timer
my $start = time();

my $blast_results_file = $ARGV[0];    #FASTA

#$uniprot_file = $ARGV[1];

open IN, "$blast_results_file" or die "can't open file";

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
    #print $entry, "\t", join("\t", @{ $topHit{$entry} } ), "\n";
  print $entry, "\t", $acc, "\_", $spec, "\_", $eval, "\t";
  
#print "ID: $acc: ";

  my $base = "http://www.uniprot.org/uniprot/";
  my $query = "$acc.xml";
  my $url = "$base$query";
#  print "\n", $url, "\n";
#  my $email = "&email=mike\@intermine.org";

#   my $agent    = LWP::UserAgent->new;
#   my $request  = HTTP::Request->new(GET => $url);
#   my $response = $agent->request($request);
#   $response->is_success or print "$entry\tError: " . 
#   $response->code . " " . $response->message, "\n";
#  print $response->content, "\n";

  my $response = get($url);

  my $twig = new XML::Twig( twig_handlers => 
			  { 
					     protein => \&prot_name,
					     dbReference => \&dbRef
			  }  
  ); 

# the prot_name and dbRef function will be called every time a protein element is processed

#  $twig->parse($uniprot_result);
  $twig->parse($response);
  $twig->purge;

  print "\n";

#print $upEntry, "\n";
}

sub prot_name {
  my ($twig, $prot) = @_; # twig is the whole twig; prot is the element being processed
  print $prot->first_descendant('fullName')->text, "\t";
  $twig->purge
}

sub dbRef {
  my ($twig, $elt)= @_;

  my (@GO, @PFAM);

  if ($elt->att('type') eq 'ZFIN') {
    print $elt->att('id'), "-";
    print $elt->first_descendant('property')->att('value'), "; ";
  }

  if ($elt->att('type') eq 'Pfam') {
    print $elt->att('id'), "-";
    if (my $geneName = $elt->first_descendant('property') ) {
      print $elt->first_descendant('property')->att('value'), "; ";
    }
  }

  if ($elt->att('type') eq 'GO') {
    print $elt->att('id'), "-";
    print $elt->first_descendant('property')->att('value'), "; ";
  }

  $twig->purge;
}




#foreach $locus ( keys %accession ) {
#    $accession_hash{ $accession{$locus} } = 1;
#}

# open IN, "$uniprot_file" or die "can't open file";
# $hit = 0;
# while (<IN>) {
#     if ( $_ =~ /^AC\s+(.+);/ ) {
# 
#         @accessions = split( /; /, $1 );
# 
#         $hit = 0;
#         foreach $syn (@accessions) {
#             if ( $accession_hash{$syn} ) {
#                 $current_accession = $syn;
#                 $hit               = 1;
#             }
# 
#         }
# 
#     }
#     if ( $hit == 1 ) {
#         if ( $_ =~ /^OS\s+(.+)/ ) { $os{$current_accession} = $1; }
#         if ( $_ =~ /^OC\s+(.+)/ ) { $oc{$current_accession} .= "$1 "; }
#         if ( $_ =~ /^DR\s+Pfam; (.+)/ ) {
#            $current_pfam{$current_accession} .= "$1 ";
#         }
#         if ( $_ =~ /^DR\s+GO; (.+)/ ) {
#             $current_go{$current_accession} .= "$1 ";
#         }
#         if ( $_ =~ /^DE\s+(.+)/ ) {
#             $current_fullname{$current_accession} = $1;
#         }
#         if ( $_ =~ /^GN\s+(.+)/ ) { $current_name{$current_accession} = $1; }
#     }
# }
# 
# foreach $locus ( keys %orgm ) {
# 
#     print
# "$locus\t$evalue{$locus}\t$accession{$locus}\t$current_name{$accession{$locus}}\t$current_fullname{$accession{$locus}}\t$current_pfam{$accession{$locus}}\t$current_go{$accession{$locus}}\t$os{$accession{$locus}}\t$oc{$accession{$locus}}\n";
# 
# }
# 
# # end timer
# my $end = time();

# report
#print "\nTime taken was ", ( $end - $start ), " seconds\n";

