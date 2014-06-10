#!/usr/bin/perl -w

use strict;
use warnings;

use LWP::Simple;
use XML::Twig;

my $uniprotID = "E7F7B9.xml";

print "ID: $uniprotID: ";

# my $protXMLdir = "/home/ml590/sdata/adrian_shared_files/uniprot_cache/";
# #my $protFile = "$acc.xml";
# 
#   open PROTxml, "$protXMLdir$uniprotID" or warn "can't open file";
# 
#   while (<PROTxml>) {
#    print "Opening file: $uniprotID\n", "Printing...", $_;
# }

my $url = "http://www.uniprot.org/uniprot/";

my $uniprot_result = get($url . $uniprotID);

my $twig = new XML::Twig( twig_handlers => 
			  { 
					     protein => \&prot_name,
					     dbReference => \&dbRef
			  }  
); 

# the prot_name and dbRef function will be called every time a protein element is processed

$twig->parse($uniprot_result);
$twig->purge;

#print $upEntry, "\n";

sub prot_name {
  my ($twig, $prot) = @_; # twig is the whole twig; prot is the element being processed
  print $prot->first_descendant('fullName')->text, "\t";
  $twig->purge
}

sub dbRef {
  my ($twig, $elt)= @_;

#  my (@GO, @PFAM);

  if ($elt->att('type') eq 'Pfam') {
    print $elt->att('id'), "-";
    print $elt->first_descendant('property')->att('value'), "; ";
  }

  if ($elt->att('type') eq 'GO') {
    print $elt->att('id'), "-";
    print $elt->first_descendant('property')->att('value'), "; ";
  }

  $twig->purge;
}

