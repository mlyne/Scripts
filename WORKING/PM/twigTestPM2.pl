#!/usr/bin/perl
use strict;
use warnings;
use XML::Twig::XPath;
use LWP;

# Take input from the command line

my $inFile = $ARGV[0];

open(IFILE, "< $inFile") || die "cannot open $inFile: $!\n";

$/ = undef;

my @entries;
my @lines;

while (<IFILE>)
{
	@entries = split(/\n\n/, $_);
}

shift(@entries);

# Close the file we've opened
close(IFILE);

$/ = "\n";

foreach my $entry (@entries)
{
	#print "\nNEW ENTRY: \n", $entry, "\nEND ENTRY\n\n";

	my $twig = XML::Twig::XPath->new->parse($entry);
	#$twig->parse( $entry );

	my ($title) = $twig->findnodes('//ArticleTitle');
	print "TITLE: ", $title->getValue,"\n";

	#my @abst = $twig->findnodes('//AbstractText');
	#print "ABSTRACT: ", $_->getValue,"\n" foreach @abst; 

	#my @authors = $twig->findnodes('//Article/AuthorList/Author');
	#print "AUTHOR: ", $_->getValue,"\n" foreach @authors; 

#	my @mesh = $twig->findnodes('//MeshHeadingList/MeshHeading');
#	print "MESH: ", $_->getValue,"\n" foreach @mesh; 
#	print "MESH: ", $_->string_value,"\n" foreach @mesh;

	my @mesh = $twig->findnodes('//DescriptorName');
#	print "MESH: ", $_->getValue,"\n" foreach @mesh; 
#	print "MESH: ", $_->string_value,"\n" foreach @mesh;

        foreach my $mhRef (@mesh)
        {
        my $meshTerm = $mhRef->getValue;
        
        # Make use of LWP to make call to PubMed query website

        my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?&db=mesh&term=$meshTerm" . # test URL 2
        "[mh]" .
        "&tool=eSearchTool" .
        "&email=mlyne\.careers\@gmail.com";
                
        my $agent    = LWP::UserAgent->new;
        my $request  = HTTP::Request->new(GET => $url);
        my $response = $agent->request($request);
        $response->is_success or print "$meshTerm\tError: " . 
        $response->code . " " . $response->message, "\n";
        select(undef, undef, undef, 0.1); # PubMed requires that we have no more than 3 requests / second so delay half second
        
        my $res; # Declare for results processing

# Results are slurped back in HTML format- we only want the Summary Text data
# Split each line into the array

        $res = $response->content;
        #print $response->content, "\n";
        my $valid = "true" if ($res =~ m/eSearchResult/);

# Then use grep to retrieve the line with MeSH ID info

	my ($meshId) = defined $valid ? ($res =~ m/\<Id\>(\d+)\</) : ("12321");

	print "MeSH Term: ", $meshTerm, "\(ID: $meshId\)\n"; 

	my $efetchurl = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?&db=mesh&id=$meshId" . # test URL 2
        "&report=full" .
        "&tool=eSearchTool" .
        "&email=mlyne\.careers\@gmail.com";
                
        my $agent2    = LWP::UserAgent->new;
        my $request2  = HTTP::Request->new(GET => $efetchurl);
        my $response2 = $agent2->request($request2);
        $response2->is_success or print "$meshId\tError: " . 
        $response2->code . " " . $response2->message, "\n";
        select(undef, undef, undef, 0.1); # PubMed requires that we have no more than 3 requests / second so delay half second
        
        my $meshHit; # Declare for results processing

# Results are slurped back in HTML format- we only want the Summary Text data
# Split each line into the array

        $meshHit = $response2->content;
        #print $response->content, "\n";
#        my $valid = "true" if ($res =~ m/MeSH Categories/);

# Write MeSH IDs
#	print "MESH: ", $meshHit, "\n";
#	print "MESH: ", $mh->string_value, "\n";

# Declare array to process MeSH tree
	my @meshTree = split(/\n/, $meshHit);
#	print "MESH: ", $_, "\n" foreach @meshTree;
	foreach my $line (@meshTree)
	{

	if ($line =~ /^         /)
	{
	print "TREE: ", $line, "\n";
	}

	}
#	do
#	{
#	shift @meshTree;
#	} until (m/All MeSH Categories/);
	
        }
print "--- END ---\n";

}

