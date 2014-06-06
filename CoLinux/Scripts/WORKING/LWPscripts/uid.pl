#!/usr/bin/perl -w
 
use LWP;
use strict;
 
my $file = $ARGV[0];

print "88-0619\n6MJYATY\n\n\n\n";

open(FILEO, "< $file") || die "cannot open $file: $!\n";

READ_LOOP:while (<FILEO>)
{
  	my $pmid = (/(\d+)/) ? $1 : die "Not a PMID or Wrong fileformat\nPlease check your file!: $!\n";
	#print "PMID $pmid\n";
#chomp(my $pmid = <STDIN>);

	my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=text&db=PubMed&uid=$pmid&dopt=summary";  

	my $agent    = LWP::UserAgent->new;
	my $request  = HTTP::Request->new(GET => $url);
	my $response = $agent->request($request);
	$response->is_success or die "failed";

	my @ref = split /\n/, $response->content;
	#my @ref = split /^\n/, $response->content;
	
	unless ($ref[3] =~ /\)\:\d/) { splice(@ref, 3, 1) };

	my $auth = $ref[1];
	$auth =~ s/^\d+:\s+//;
	$auth = (length($auth le 40)) ? $auth : substr($auth, 0, 40);

	my $titl = $ref[2];
	$titl =~ s/^\s+//;
	$titl =~ s/(\[|\])//g;
	$titl = (length($titl le 40)) ? $titl : substr($titl, 0, 40);

	my $journ = $ref[3];
	$journ =~ s/^\s+//;
	my ($jtit, $jdet) = ($journ =~ /^(.+?)(\d.+)\w/);
	$jdet =~ s/\. \w.+//;
	$jtit = (length($jtit le 40)) ? $jtit : substr($jtit, 0, 40);
	$jdet = (length($jdet le 40)) ? $jdet : substr($jdet, 0, 40);

#	print "TXPHOTO\n";
#	print $jtit, "\n";
#	print $jdet, "\n";
#	print $titl, "\n";
#	print $auth, "\n";
#	print "\n\n\n\n";

print join("*", @ref), "\n";

}
print "NNNN\n";



 
