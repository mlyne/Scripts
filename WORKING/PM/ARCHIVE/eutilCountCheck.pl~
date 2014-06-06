#!/usr/bin/perl
use strict;
use warnings;

my ($entry, $drugExp, $url);

$drugExp = \(\"aston university\"\[ad\]\);
$entry =  \(\"abeta\"\[tiab\] AND \(\"alzheimer disease\"[mh] OR \"alzheimer's\"\[tiab\]\)\);

        $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?&db=pubmed&rettype=count&term=$drugExp" . # test
 URL 2
        "+AND+$entry+NOT+review[pt]" .
        "&tool=eSearchTool" .
        "&email=mlyne\.careers\@gmail.com";
                
        my $agent    = LWP::UserAgent->new;
        my $request  = HTTP::Request->new(GET => $url);
        my $response = $agent->request($request);
        $response->is_success or print "$drugName, $entry\tError: " . 
        $response->code . " " . $response->message, "\n";
        select(undef, undef, undef, 0.1); # PubMed requires that we have no more than 3 requests / second so delay half second
        
        my $res; # Declare array for results processing

# Results are slurped back in HTML format- we only want the Summary Text data
# Split each line into the array

        $res = $response->content;
        print $response->content, "\n";
