#!/usr/bin/env perl
use strict;
use warnings;

use feature ':5.12';

use InterMine::Item::Document;
use InterMine::Model;

my $usage = "script.pl

";

my ($model_file) = $ARGV[0];

unless ( $ARGV[0] ) { die $usage }

my $model = new InterMine::Model(file => $model_file);
my $doc = new InterMine::Item::Document(model => $model);

my $data_source_item = make_item(
    DataSource => (
        name => "EggNOG: evolutionary genealogy of genes",
	url => "http://eggnog.embl.de/",
    ),
);

my $ortholog_data_set_item = make_item(
    DataSet => (
        name => "EggNOG Non-supervised Orthologous Groups",
    ),
);

my $funccat_data_set_item = make_item(
    DataSet => (
        name => "EggNOG Functional Categories",
    ),
);

$doc->close(); # writes the xml
exit(0);

######### helper subroutines:

sub make_item {
    my @args = @_;
    my $item = $doc->add_item(@args);
#     if ($item->valid_field('organism')) {
#         $item->set(organism => $org_item);
#     }
    return $item;
}
