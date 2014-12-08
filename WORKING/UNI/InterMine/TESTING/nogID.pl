#!/usr/bin/env perl
use strict;
use warnings;

use feature ':5.12';

my $usage = "nogID.pl

";

my ($taxon_file, $id_file) = @ARGV;
unless ( $ARGV[1] ) { die $usage }

open my $taxons_fh, "$taxon_file" or die "can't open file: $taxon_file $!\n";
my @taxon_list = split(" ", <$taxons_fh>);
close ($taxons_fh);

my @tax_expr;
for my $taxon (@taxon_list) {
  $taxon =~ s/^/\^/;
#  $taxon =~ s/$/\\b/;
  push(@tax_expr, $taxon);
}

my $tax_regExp = join("|", @tax_expr);
say $tax_regExp;

my @found = `grep -w -E $tax_regExp $taxon_file`;
say "Found? ", join("", @found);

my (%id_lookup);
open my $id_fh, "$id_file" or die "can't open file: $id_file $!\n";

my @orgs = grep { /$tax_regExp/ && /BLAST_KEGG_ID/ } <$id_fh>;

# while (<$id_fh>) {
#   chomp $_;
# 
#   for my $taxon (@taxon_list) {
#     if ( ($_ =~ /$tax_regExp/) && ($_ =~ /BLAST_KEGG_ID/ ) ) {
#       my ($taxon, $nog_id, $kegg_id, undef) = split("\t", $_);
#       my ($kegg_org, $org_id) = split(":", $kegg_id);
#       my $taxon_nogID = $taxon . "\." . $nog_id;
#       $id_lookup{$taxon_nogID} = $org_id;
#     }
#   }
# }

close ($id_fh);

say join("", @orgs);