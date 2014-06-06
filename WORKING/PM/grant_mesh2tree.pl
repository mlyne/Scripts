#!/usr/bin/perl
use strict;
use warnings;

my $usage = "Usage:term2treeMesh.pl mesh_tree " .
    "mesh_term_file\n";

unless ( $ARGV[1] ) { die $usage }

my $meshTree = $ARGV[0];
my $termFile = $ARGV[1];

my ($concept, $treePath);
our %conceptHash;
my %pathHash;
my %meshCnt;

open(TREE_FILE, "< $meshTree")  || die "cannot open $meshTree: $!";

while (<TREE_FILE>)
{
  chomp;
  ($concept, $treePath) = split(/;/, $_);
  $conceptHash{$concept} = $treePath;
  $pathHash{$treePath} = $concept;
}

close(TREE_FILE);

open(TERM_FILE, "< $termFile")  || die "cannot open $termFile: $!";

#foreach my $key (sort keys %pathHash) 
#{
#  print "KEY: ", $key, "\tVAL: ", $pathHash{$key}, "\n"; 
#  print " VAL: ", $pathHash{$key}, "\tKEY: ", $key, "\n";
#}

my @entries;


$/ = undef;

while (<TERM_FILE>) {
  @entries = split("--- RECORD ---\n", $_);
}
    
#print "HERE: ", join("\nEND\n", @entries), "\n";

$/= "\n";

foreach my $entry (@entries) {
  my ($term, $mesh, $grant) = split("\n", $entry);
  
  chomp ($term, $mesh, $grant);
  
    $mesh =~ s/MESH HITS: //;
    $mesh =~ s/ and Neonatal Diseases and Abnormalities//g;
    $mesh =~ s/Diseases/Dis/g;
    
    my @meshHits = split("\; ", $mesh);
    
    my $meshRef = &MeSH(\@meshHits);
    my @meshDis = @{ $meshRef };
    next unless (@meshDis);
#    print "MeSH: ", join("; ", @meshDis), "\n";

    $grant =~ s/GRANT HITS: //;
    $grant =~ s/ HHS//g;
    
# Institute names
    $grant =~ s/Canadian Institutes of Health Research/CIHR/;
    
    $grant =~ s/Howard Hughes Medical Institute/HowardHughes/;

    $grant =~ s/Medical Research Council/MRC/;
    $grant =~ s/Department of Health/DoH/;
    $grant =~ s/Biotechnology and Biological Sciences Research Council/BBSRC/;
    $grant =~ s/Cancer Research UK/CRUK/;
    $grant =~ s/Wellcome Trust/WT/;
    $grant =~ s/British Heart Foundation/BHF/;
    
    my @grantHits = split("\; ", $grant);
    my @uniqGrant = do { my %seen; grep { !$seen{$_}++ } @grantHits };
    
    foreach my $meshTerm (@meshDis) {
    
      $meshTerm =~ s/, and Neonatal Diseases and Abnormalities//g;
      $meshTerm =~ s/Diseases/Dis/g;
      $meshTerm =~ s/ and Pregnancy Complications//g;
    
      foreach my $grant (@uniqGrant) {
	$grant =~ /(.+)\:(.+)/;
	my ($fund, $cntry) = ($1, $2);
	print $meshTerm, "\t", $fund, "\t", $cntry, "\n";
      }
    }
    
#     my $grantRef = &Grant(\@grantHits);
#     my @grants = @{ $grantRef };
#     next unless (@grants);
#     print "Grant: ", join("; ", @grants), "\n";

}

sub MeSH {
  my $mhRef = shift;
  my @mhTerms = @{ $mhRef };
  
  my @meshDis;
  
  foreach my $mhTerm ( @mhTerms ) {
  
    if ( exists($conceptHash{$mhTerm}) ) {
      my (@path) = split(/\./, $conceptHash{$mhTerm});
      my $rootNode = $path[0];
      if ($rootNode =~ /C\d\d/) {
	next if ($rootNode =~ /C23/);
	push( @meshDis, $pathHash{$rootNode} );
#	print "MeSH: ", $pathHash{$rootNode}, "\tTREE: ", $rootNode, "\n";
      }
    }
  }
    
  my @uniqMesh = do { my %seen; grep { !$seen{$_}++ } @meshDis };
  return ( \@uniqMesh );
  
}

# sub Grant {
#   my $grRef = shift;
#   my @grants = @{ $grRef };
#   
#   foreach my $grant ( @grants ) {
#     $grant =~ /(.+)\:(.+)/;
#     my ($fund, $cntry) = ($1, $2);
#     print $fund, "\t", $cntry, "\n";
#   }
#     
# #   my @uniqMesh = do { my %seen; grep { !$seen{$_}++ } @meshDis };
# #   return ( \@uniqMesh );
#   
# }
