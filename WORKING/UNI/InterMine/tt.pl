#!/usr/bin/perl
#
#

use strict;
use warnings;
use feature ':5.12';

# my %bad_symbols;
# my $non_unique_symbols = "ydzW ydzT fabG yrdD appA aroE carB cbiO def hemD iscS ispA nagP natA natB nrdF nrdI pgsA ppnK rpmG rpsN sat sfp swrAA thyA tuaA ydhU ydzS yetI ymfK ymzE yoyK ypqP ypuC yqbN yusY yxiT";
# my @non_unique_symbols = split(" ", $non_unique_symbols);
# 
# for my $bad (@non_unique_symbols) {
#   $bad_symbols{$bad}++;
# }

binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

#my $region = shift;
my $region = "NC_000913.3:2598423..2598999";
$region =~ m/(NC_.+)\:/;
my $chromosome = $1; 

$chromosome or die { "not found: $chromosome\n" };

my $org_short = &fetch_organism( $chromosome );
say $org_short, "\n";
my ($found_gene, $expression_ref) = &regionSearch($region, $org_short);

say $found_gene, "\n";

my @results = @$expression_ref;
#print "Here:", $results[-1], "\n";

for my $result (@results) {
  say join("\t", @{ $result });
}

say "\n";

sub fetch_organism {
  use Webservice::InterMine 0.9904 'http://met1:8080/synbiomine-exper';

  my $chromosome = shift;

  my $chrom_query = new_query(class => 'Chromosome');

  # The view specifies the output columns
  $chrom_query->add_view(qw/
      primaryIdentifier
      organism.shortName
  /);

  $chrom_query->add_constraint(
      path  => 'Chromosome.primaryIdentifier',
      op    => '=',
      value => "$chromosome",
      code  => 'A',
  );

  # Use an iterator to avoid having all rows in memory at once.
  my $org_short;
  my $it = $chrom_query->iterator();

  while (my $row = <$it>) {
    $org_short = $row->{'organism.shortName'};
  }
  return $org_short;
}

sub regionSearch {

  use Webservice::InterMine::Bio::RegionQuery qw/GFF3/;
  use Webservice::InterMine 0.9904;

  my ($region, $org_short) = @_;

  # my $service = Webservice::InterMine->get_service('http://www.flymine.org/synbiomine');
  my $service = Webservice::InterMine->get_service('http://met1:8080/synbiomine-exper');
  my $region_query = Webservice::InterMine::Bio::RegionQuery->new(
      service => $service,
      organism => "$org_short",
      regions => ["$region", ],
      feature_types => ["Gene"]
  );

  my $gffRes = $region_query->gff3;
  my @gffs = split("\n", $gffRes);
  shift(@gffs);

  print join("\n", @gffs), "\n";

  foreach my $gff (@gffs) {
    my @gff_fields = split("\t", $gff);
    my $gene_field = pop(@gff_fields);
    $gene_field =~ m/ID=(.+)/;
    my $gene = $1;
    print $gene, "\n";

    my ($found_gene, $expression_ref) = &fetch_expression($gene, $org_short);
    return ($found_gene, $expression_ref);

  }
}

sub fetch_expression {

  use Webservice::InterMine 0.9904 'http://met1:8080/synbiomine-exper';

  my ($gene, $org_short) = @_;

  my $query = new_query(class => 'Gene');

  # The view specifies the output columns
  $query->add_view(qw/
      primaryIdentifier
      expressionResults.condition.name
      expressionResults.log2FoldChange
      expressionResults.meanExpr
      expressionResults.CV
      chromosome.primaryIdentifier
      chromosomeLocation.start
      chromosomeLocation.end
      chromosomeLocation.strand
      organism.shortName
      organism.taxonId
      expressionResults.dataSet.name
  /);

  $query->add_constraint(
      path        => 'Gene',
      op          => 'LOOKUP',
      value       => "$gene",
      extra_value => "$org_short",
      code        => 'A',
  );

  # Use an iterator to avoid having all rows in memory at once.
  my $it2 = $query->iterator();
  my @results;
  while (my $row = <$it2>) {
    push (@results, [$row->{'primaryIdentifier'}, 
		      $row->{'expressionResults.condition.name'},
		      $row->{'expressionResults.log2FoldChange'}, 
		      $row->{'expressionResults.meanExpr'},
		      $row->{'expressionResults.CV'}, 
		      $row->{'chromosome.primaryIdentifier'},
		      $row->{'chromosomeLocation.start'},
		      $row->{'chromosomeLocation.end'},
		      $row->{'chromosomeLocation.strand'}, 
		      $row->{'organism.shortName'},
		      $row->{'organism.taxonId'}, 
		      $row->{'expressionResults.dataSet.name'},])

  }
    return ($gene, \@results);
#  }
}
