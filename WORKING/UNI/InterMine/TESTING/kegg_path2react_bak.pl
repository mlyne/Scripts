#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
require LWP::UserAgent;

use feature ':5.12';

use InterMine::Item::Document;
use InterMine::Model;

# Print unicode to standard out
binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

my $usage = "usage: $0 intermine_model_file output_directory_path

Script to retrieve KEGG reactions and associated pathways
Writes an items XML with reaction/ pathway mappings

# Options
-v\tverbose output

\n";

### command line options ###
my (%opts, $verbose);

getopts('hv', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"v"} and $verbose++;

unless ( $ARGV[0] ) { die $usage };

my ($model_file, $out_dir) = @ARGV;
$out_dir = ($out_dir) ? $out_dir : "\.";

#my $taxon_id = ($org) ? $org : "224308";
my $data_source_name = "GenomeNet";
my $kegg_url = "http://www.kegg.jp/";

# instantiate the model
my $model = new InterMine::Model(file => $model_file);
my $doc = new InterMine::Item::Document(model => $model);

# # my $org_item = make_item(
# #     Organism => (
# #         taxonId => $taxon_id,
# #     )
# # );

my $data_source_item = make_item(
    DataSource => (
        name => $data_source_name,
	url => $kegg_url,
    ),
);

my $reactions_data_set_item = make_item(
    DataSet => (
        name => "KEGG reactions data set",
	dataSource => $data_source_item,
    ),
);

#open(ORG_FILE, "< $org_file") || die "cannot open $org_file: $!\n";

say "Executing KEGG pathways script" if ($verbose);

# Process reactions
my (%seen_reaction_items);
my $react_url = "http://rest.kegg.jp/list/reaction";
my $reactions = &kegg_ws($react_url);
&process_reactions($reactions);

# Process Reaction to Pathways mappings
my (%seen_pathway_items);
my $react2path_url = "http://rest.kegg.jp/link/pathway/reaction";
my $mappings = &kegg_ws($react2path_url);
&process_mappings($mappings);

$doc->close(); # writes the xml
exit(0);

say "All done - enjoy your results" if ($verbose);
exit(0);

## sub routines ##
sub kegg_ws {

  my $url = shift;

  my $agent = LWP::UserAgent->new;

  my $request  = HTTP::Request->new(GET => $url);
  my $response = $agent->request($request);

  $response->is_success or say "Error: " . 
  $response->code . " " . $response->message;

  return $response->content;

}

sub process_reactions {

  my ($content) = shift;

  open my ($str_fh), '+<', \$content; # process 

  while (<$str_fh>) {
    chomp;
    $_ =~ s/^rn://;
    my ($reaction, $name) = split("\t", $_);
#    $reactions{$reaction} = $name;
    say "line $reaction $name" if ($verbose);

    my $reaction_item = make_item(
      Reaction => (
	identifier => $reaction,
	name => $name,
	dataSets => [ $reactions_data_set_item ],
      ),
    );
    $seen_reaction_items{$reaction} = $reaction_item;
  }

  close ($str_fh);
}

sub process_mappings {

  my ($content) = shift;

#  my $out_file = $org . "_gene_map.tab";
# #   open (OUT_FILE, ">$out_dir/$out_file") or die $!;
# #   say "Writing to $out_dir/$out_file" if ($verbose);

  open my ($str_fh), '+<', \$content; # process 

  while (<$str_fh>) {
    chomp;
    next if ($_ =~ /map/);
    $_ =~ s/path://;
    $_ =~ s/rn:?//g;

    my ($reaction, $pathway) = split("\t", $_);
    say "line $reaction - $pathway" if ($verbose);

    my $reaction_item = &make_reaction_item($reaction);
    next unless $reaction_item;

    my $pathway_item = &make_pathway_item($pathway, $reaction_item);
    if ($pathway_item) {
    push( @{ $reaction_item->{'pathways'} }, $pathway_item); 
    } else {
      warn "Ooops! didn't find a pathway item for $pathway\n";
    }
  }

  close ($str_fh);
}

######## helper subroutines:

sub make_item {
    my @args = @_;
    my $item = $doc->add_item(@args);
#    if ($item->valid_field('organism')) {
#        $item->set(organism => $org_item);
#    }
    return $item;
}

sub make_reaction_item {
  my $id = shift;

  my $reaction_item;
  if (exists $seen_reaction_items{$id}) {
    $reaction_item = $seen_reaction_items{$id};
  } else {
    warn "Error: no reaction found for $id\n";
    return;
  }
  return $reaction_item;
}

sub make_pathway_item {
  my ($id, $reaction_item) = @_;

  my $pathway_item;
  if (exists $seen_pathway_items{$id}) {
    say "Processing pathway $id" if ($verbose);

    push( @{ $seen_pathway_items{$id} ->{'reactions'} }, $reaction_item);
    $pathway_item = $seen_pathway_items{$id};
  } else {
    say "Haven't seen pathway $id - making one" if ($verbose);
    $pathway_item = make_item(
      Pathway => (
	identifier => $id,
	reactions => [ $reaction_item ],
      ),
    );
    $seen_pathway_items{$id} = $pathway_item;
  }
  return $pathway_item;
}