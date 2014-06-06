#!/usr/bin/perl -w

use LWP;
use strict;
use Getopt::Std;

my $usage = "Usage: \n
Description:
-o\tDocSum
-d\tDetailed
-s\tSynopsis
-v\tVariants
-m\tMiniMIM
-a\tASN1
-e\tExternalLink
";


### command line options ###
my (%opts, $doc, $det, $syn, $vari, $mini, $asn1, $ext);

my $format;
getopts('hodsvmae', \%opts);
defined $opts{"h"} and die $usage;
defined $opts{"o"} and $format = "DocSum";
defined $opts{"d"} and $format = "Detailed";
defined $opts{"s"} and $format = "Synopsis";
defined $opts{"v"} and $format = "Variants";
defined $opts{"m"} and $format = "MiniMIM";
defined $opts{"a"} and $format = "ASN1";
defined $opts{"e"} and $format = "ExternalLink";

while (<>) {
	chomp;
	my ($prot, $mRNA, $omim) = split("\t", $_);
	print ">$prot\t$mRNA\t$omim\n";
	my ($results) = omim($omim);
	print "$$results\n--------- END RESULT -------\n\n";

}

sub omim {

	my $omim = shift;
	my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Text" .
	"&db=OMIM&uid=$omim&dopt=$format";
	my $agent    = LWP::UserAgent->new;
	my $request  = HTTP::Request->new(GET => $url);
	my $response = $agent->request($request);
	$response->is_success or die "failed";
	my ($result) = $response->content;
	return \$result;
	
}
