#!/usr/bin/perl

use strict;
use warnings;
require LWP::UserAgent;

use feature ':5.12';

my @orgs = qw|eco bsu bai ecc|;

say "Executing KEGG pathways script";

for my $org (@orgs) {
  say "Processing organism: $org";

  my $content = &kegg_ws($org);
  sleep(3);
  &process_kegg($org, $content);

}

say "All done - enjoy your results";
exit(1);

## sub routines ##
sub kegg_ws {

  my $org = shift;
  my $base = "http://rest.kegg.jp/link/pathway/";
  my $url = "$base$org";

  my $agent = LWP::UserAgent->new;

  my $request  = HTTP::Request->new(GET => $url);
  my $response = $agent->request($request);

  $response->is_success or say "$org - Error: " . 
  $response->code . " " . $response->message;

  return $response->content;

}

sub process_kegg {

  my ($org, $content) = @_;

  my %gene2path;

  my $out_file = $org . "_g2p.txt";
  open (OUT_FILE, ">$out_file") or die $!;

  open my ($str_fh), '+<', \$content;

  while (<$str_fh>) {
    chomp;
    $_ =~ s/path:$org//;
    $_ =~ s/$org://;
    my ($gene, $path) = split("\t", $_);
    push( @{ $gene2path{$gene} }, $path );
#    say "line $gene - $path";
  }

  close ($str_fh);

  my @sorted = map  { $_->[0] }
               sort { $a->[1] <=> $b->[1] }
               map  { /[A-Za-z_]+(\d+)/ and [$_, $1] }
               keys %gene2path;

  for my $key (@sorted) {

#  for my $key (sort { $gene2path {$a} <=> $gene2path {$b} } keys %gene2path) {
    say OUT_FILE $key, "\t", join(" ",  @{ $gene2path{$key} } );
  }
  say "Finished $org\n";
  close (OUT_FILE);

}
