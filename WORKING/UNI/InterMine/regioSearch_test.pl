#!/usr/bin/perl
#
#

use strict;
use warnings;
use Data::Dumper;

# Set the output field separator as tab
$, = "\t";
# Print unicode to standard out
binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

# This code makes use of the Webservice::InterMine library.
# The following import statement sets SynBioMine Experimental as your default
use Webservice::InterMine::Bio::RegionQuery qw/GFF3 BED/;
use Webservice::InterMine 0.9904;

#my $region = "NC_000913.3:2598423..2598460";
my $region = "NC_000913.3:2598423..2598999";
my $organism = "E. coli str. K-12 substr. MG1655";

# my $service = Webservice::InterMine->get_service('http://www.flymine.org/synbiomine');
my $service = Webservice::InterMine->get_service('http://met1:8080/synbiomine-exper');
my $region_query = Webservice::InterMine::Bio::RegionQuery->new(
    service => $service,
#    organism => "E. coli str. K-12 substr. MG1655",
#    regions => ["NC_000913.3:2598423..2598460", ],
    organism => "$organism",
    regions => ["$region", ],
    feature_types => ["Gene"]
);

print "Sequence data...", "\n";
# print $region_query->bed;
# print $region_query->fasta;
my $gffRes = $region_query->gff3;
my @gffs = split("\n", $gffRes);
shift(@gffs);

#print join("\n", @gffs), "\n";

my @genes = map { m/ID=(.+)/ ? $1 : $_ } @gffs;

print "GENES: ", join(", ", @genes), "\n";

foreach my $gff (@gffs) {
  my @gff_fields = split("\t", $gff);
  my $gene_field = pop(@gff_fields);
  $gene_field =~ m/ID=(.+)/;
  my $gene = $1;
#  print $gene, "\n";


#my $test_gene = "BSU30400";
#my $organism = "B. subtilis subsp. subtilis str. 168";

# my $test_gene = "EG11149";
# my $organism = "E. coli str. K-12 substr. MG1655";
# 
  use Webservice::InterMine 0.9904 'http://met1:8080/synbiomine-exper';

  my $query = new_query(class => 'Gene');

  # The view specifies the output columns
  $query->add_view(qw/
      primaryIdentifier
      organism.shortName
      expressionResults.log2FoldChange
      expressionResults.CV
      expressionResults.meanExpr
      expressionResults.condition.name
  /);

  # edit the line below to change the sort order:
  # $query->add_sort_order('primaryIdentifier', 'ASC');

  $query->add_constraint(
      path        => 'Gene',
      op          => 'LOOKUP',
      value       => "$gene",
      extra_value => "$organism",
      code        => 'A',
  );


  # Use an iterator to avoid having all rows in memory at once.
  my $it = $query->iterator();
  my @results;
  while (my $row = <$it>) {
    push (@results, [$row->{'primaryIdentifier'}, 
		      $row->{'organism.shortName'},
		      $row->{'expressionResults.log2FoldChange'}, 
		      $row->{'expressionResults.CV'},
		      $row->{'expressionResults.meanExpr'}, 
		      $row->{'expressionResults.condition.name'}])

  #     print $row->{'primaryIdentifier'}, $row->{'organism.shortName'},
  #         $row->{'expressionResults.log2FoldChange'}, $row->{'expressionResults.CV'},
  #         $row->{'expressionResults.meanExpr'}, $row->{'expressionResults.condition.name'}, "\n";
  }

  for my $result (@results) {
    print join("\t", @{ $result }), "\n";
  }

}