#!/usr/bin/perl -w

use strict;
use warnings;
use feature ':5.12';

use InterMine::Item::Document;
use InterMine::Model;

my $usage = "usage: $0 model_file

\n";

my $model_file = $ARGV[0];

unless ( $ARGV[0] ) { die $usage }

my $taxon_id = "224308";
my $title = "DBTBS - Regulatory features for Bacillus subtilis 168";
my $url = "http://dbtbs.hgc.jp";
my $chromosome = "NC_000964.3";

my $model = new InterMine::Model(file => $model_file);
my $doc = new InterMine::Item::Document(model => $model);

my $org_item = make_item(
    Organism => (
        taxonId => $taxon_id,
    )
);

my $data_source_item = make_item(
    DataSource => (
        name => $title,
	url => $url,
    ),
);

my $data_set_item = make_item(
    DataSet => (
        name => "DBTBS Promoters for taxon id: $taxon_id",
	dataSource => $data_source_item,
    ),
);

my $chromosome_item = make_item(
    Chromosome => (
        primaryIdentifier => $chromosome,
    ),
);

my @evidence = (
    [qw/ AR GS NB /],
    [qw/ CH AR /],
    [qw/ DP ROMA /],
);

my $evidenceRef;
for my $e (@evidence) {
  say "looking up codes: ", join(';', @{ $e } );
  $evidenceRef = &evidence_lookup($e);
}

$doc->close(); # writes the xml
exit(0);

### subs ###

sub evidence_lookup {
  
  my $evidenceRef = shift;
  my @evidence_codes = @{ $evidenceRef };

  my %evidence = <<END =~ /(\w+)\t(.+)/g;
AR	DNA microarray and macroarray
CH	Chromatin immunoprecipitation microarray (ChIP-on-chip)
DB	Disruption of Binding Factor gene
DP	Deletion assay
FT	Footprinting assay (DNase I, DMS, etc.)
FP	Fluorecent protein
GS	Gel retardation assay
HB	Slot blot analysis
HM	Homology search
OV	Overexpression of Binding Factor gene
PE	Primer extension analysis
RG	Reporter gene (e.g., lacZ assay)
RO	Run-off transcription assay
ROMA	Run-off transcription followed by macroarray analysis
S1	S1 mapping analysis (S1 nuclease transcript mapping)
SDM	Site-directed mutagenesis (Oligonucleotide-directed mutagenesis)
NB	Northern Blot
ND	No Data
END

  my %evidenceCode_items;

  my @evidenceCode_items;
  for my $code (@evidence_codes) {
    say "Code: ", $code;
    if (exists $evidenceCode_items{$code}) {
      my $item = $evidence{$code};
      push(@evidenceCode_items, $item);
    } 
    else {
      my $evidenceCode_item = make_item(
	PromoterEvidenceCode => (
	  abbreviation => $code,
	  name => $evidence{$code},
	),
      );
      $evidenceCode_items{$code} = $evidenceCode_item;
      push(@evidenceCode_items, $evidenceCode_item);
    }
  }

  return \@evidenceCode_items;

}

######## helper subroutines:

sub make_item {
    my @args = @_;
    my $item = $doc->add_item(@args);
    if ($item->valid_field('organism')) {
        $item->set(organism => $org_item);
    }
    return $item;
}