#!/usr/bin/perl -w
 
use LWP;
use strict;
 
my $file = $ARGV[0];

print "88-0619\n6MJYATY\n\n\n\n\n";

open(FILEO, "< $file") || die "cannot open $file: $!\n";

READ_LOOP:while (<FILEO>)
{
  	my $pmid = (/(\d+)/) ? $1 : die "Not a PMID or Wrong fileformat\nPlease check your file!: $!\n";
	#print "PMID $pmid\n";
#chomp(my $pmid = <STDIN>);

	my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=text&db=PubMed&uid=$pmid&dopt=abstract";  

	my $agent    = LWP::UserAgent->new;
	my $request  = HTTP::Request->new(GET => $url);
	my $response = $agent->request($request);
	$response->is_success or die "failed";

	my @ref = split(/\n\n/, $response->content);
		
#	unless ($ref[3] =~ /\)\:\d/) { splice(@ref, 3, 1) };

	my $journ = $ref[0];
	$journ =~ s/\<pre>\n\d+:\s+//;
	my ($jtit, $jdet) = ($journ =~ /^(.+?)(\d.+)\./);
	$jdet =~ s/\. \w.+//;
	$jtit = (length($jtit le 40)) ? $jtit : substr($jtit, 0, 40);
	$jdet = (length($jdet le 40)) ? $jdet : substr($jdet, 0, 40);
	
	my $titl = $ref[1];
	$titl =~ s/^\s+//;
	$titl =~ s/(\[|\])//g;
	$titl =~ s/\n//;
	$titl = (length($titl le 40)) ? $titl : substr($titl, 0, 40);

	my $auth = $ref[2];
	$auth = (length($auth le 40)) ? $auth : substr($auth, 0, 40);




	print "TXCOPYRT\n";
	print $jtit, "\n";
	print $jdet, "\n";
#	print $journ, "\n";
	print $titl, "\n";
	print $auth, "\n";
	print "\n\n\n\n";

#print join("*\n\n", @ref), "\n";

}
print "NNNN\n";



 
