#!/usr/bin/perl -w

use LWP;
use strict;
use URI::Escape;

my $term_file = $ARGV[0];
my $range = $ARGV[1] ? "\&range=$ARGV[1]" : "\&range=1";
#print $range, "\n";

open(TFILE, "< $term_file") || die "cannot open $term_file: $!\n";

READ_TERM_LOOP:while (<TFILE>)
{
  chomp;
  my  $term = $_;

  my $query = uri_escape("$term");
#  print $query, "\n";

  my $url = "http://ops.epo.org/2.6.2/rest-services/published-data/search?q=" .
  "$query$range";

#  print $url, "\n";

  my $agent    = LWP::UserAgent->new;
  my $request  = HTTP::Request->new(GET => $url);
  my $response = $agent->request($request);
  $response->is_success or die "failed";
#  $response->code . " " . $response->message, "\n";
  select(undef, undef, undef, 6); # EPO requires that we have no more than 10 requests / minute so delay 6 seconds
  print $response->content;

}

# Close the file we've opened
close(TFILE);

### Example ###
#  "search?q=pa=university of cambridge AND cl=A61K&range=1";
#  "search?q=pa=university of cambridge" .
## cl=A61 and pa=$inst
#my $year = "\>2005";
#  "&range=1";
#  "search?q=cl=A61 AND pa=$term&range=1";
# my $inst = "\"university of cambridge\"";
# my $range = "\&range=1";