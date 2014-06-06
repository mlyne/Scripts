#!/usr/bin/perl -w
# Whisker publications trawl in PubMed.
# Rudolf Cardinal, July 2008.

use strict;

use LWP::Simple;
use XML::Twig;

my @queries = {
    "everitt bj[au] 2008[dp]",
    "cardinal rn[au]"
};

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $current_year = $year+1900;

# Whisker begins in 2000.
# This lists all potentially primary authors (authors without whose names something won't be published) who've been in since the inception.
pubmed_fetch_records("(cardinal rn[au] OR everitt bj[au] OR robbins tw[au] OR roberts ac[au]" .
                     " OR chudasama y[au] OR dickinson a[au] OR winstanley ca[au] OR di ciano p[au]" .
                     " OR aitken mr[au])" .
                     " AND (\"2000\"[PDAT] : \"$current_year\"[PDAT])"); # A1. University of Cambridge
pubmed_fetch_records("(wilkinson l[au] AND cambridge[ad]) AND (\"2000\"[PDAT] : \"$current_year\"[PDAT])"); # A1. University of Cambridge

# Other primary authors join the show later
# pubmed_fetch_records("((rowe c[au] OR bateson m[au]) AND newcastle[ad]) AND (\"2002\"[PDAT] : \"$current_year\"[PDAT])"); # A2. University of Newcastle
# pubmed_fetch_records("((dunnett sb[au] OR pearce jm[au] OR george dn[au] OR haselgrove m[au]) AND cardiff[ad]) AND (\"2004\"[PDAT] : \"$current_year\"[PDAT])"); # A3. University of Cardiff
# pubmed_fetch_records("dall sr[au] AND (\"2005\"[PDAT] : \"$current_year\"[PDAT])"); # A4. University of Exeter in Cornwall
# pubmed_fetch_records("((wills aj[au] OR suret m[au]) AND exeter[ad]) AND (\"2005\"[PDAT] : \"$current_year\"[PDAT])"); # A5. University of Exeter
# pubmed_fetch_records("(arnfred sm[au] AND copenhagen[ad]) AND (\"2004\"[PDAT] : \"$current_year\"[PDAT])"); # A6. University of Copenhagen
# pubmed_fetch_records("licata sc[au] AND (\"2005\"[PDAT] : \"$current_year\"[PDAT])"); # A7. Harvard Medical School
# # *** A8. University of Illinois at Chicago (www.uic.edu) - NO DETAILS YET
# pubmed_fetch_records("taffe ma[au] AND (\"2003\"[PDAT] : \"$current_year\"[PDAT])"); # A9. The Scripps Institute
# pubmed_fetch_records("pryce cr[au] AND (\"2004\"[PDAT] : \"$current_year\"[PDAT])"); # A10. Zurich
# pubmed_fetch_records("studtmann m[au] AND (\"2004\"[PDAT] : \"$current_year\"[PDAT])"); # A11. University of Gottingen
# pubmed_fetch_records("(carli m[au] AND negri[ad]) AND (\"2005\"[PDAT] : \"$current_year\"[PDAT])"); # A12. Instituto Ricerche Farmacologiche Mario Negri, Italy
# pubmed_fetch_records("weed mr[au] AND (\"2005\"[PDAT] : \"$current_year\"[PDAT])"); # A13. Johns Hopkins
# pubmed_fetch_records("kacelnik a[au] AND (\"2005\"[PDAT] : \"$current_year\"[PDAT])"); # A14. University of Oxford
# pubmed_fetch_records("(zurcher n[au] OR nijland mj[au]) AND (\"2006\"[PDAT] : \"$current_year\"[PDAT])"); # A15. University of Texas Health Science Center
# # *** A16. University of Minho, Portugal - NO DETAILS YET
# # A17. McGill University, Canada - chudasama y[au] - but covered by Cambridge query above.
# 
# # *** G1. Porton Down. UNCLEAR HOW TO QUERY: porton down[ad] monkey task?
# # *** G2. NIMH. UNCLEAR WHO.
# pubmed_fetch_records("(grauer e[au] AND israel[ad]) AND (\"2004\"[PDAT] : \"$current_year\"[PDAT])"); # G3. Israel Institute for Biological Research
# 
# pubmed_fetch_records("((doran s[au] OR tye s[au]) AND merck[ad])) AND (\"2004\"[PDAT] : \"$current_year\"[PDAT])"); # C1. Merck, Sharp, & Dohme
# pubmed_fetch_records("((baron sp[au] OR christoffersen c[au] OR mcnee ml[au] OR ramsey n[au]) AND pfizer[ad]) AND (\"2004\"[PDAT] : \"$current_year\"[PDAT])"); # C2. Pzifer
# pubmed_fetch_records("(vivian ja[au] AND roche[ad]) AND (\"2004\"[PDAT] : \"$current_year\"[PDAT])"); # C3. Roche
# pubmed_fetch_records("shyan-norwalt mr[au] AND (\"2003\"[PDAT] : \"$current_year\"[PDAT])"); # C4. NDA
# # *** C5. Motac - NO DETAILS
# # *** C6. TNO - NO DETAILS
# # *** C7. Deutsches Primatenzentrum GmbH - NO DETAILS
# # *** C8. Partners Healthcare - NO DETAILS
# pubmed_fetch_records("(hutcheson d[au] AND maccine[ad]) AND (\"2005\"[PDAT] : \"$current_year\"[PDAT])"); # C9. Maccine

print "FINISHED.\n";
exit;

#####################################################

sub pubmed_fetch_records {
    my $query = shift;

    my $utils = "http://www.ncbi.nlm.nih.gov/entrez/eutils";
    my $db = "pubmed";

    # Search for IDs of articles matching query.
    print "SEARCHING REMOTE DATABASE WITH QUERY: $query\n";
    my $esearch = "$utils/esearch.fcgi?" . 
                 "db=$db&retmax=1&usehistory=y&term=";
    my $esearch_result = get($esearch . $query);
    $esearch_result =~ m|<Count>(\d+)</Count>.*<QueryKey>(\d+)</QueryKey>.*<WebEnv>(\S+)</WebEnv>|s;
    my $Count    = $1;
    my $QueryKey = $2;
    my $WebEnv   = $3;
    print "Number of records found: $Count\n";
    # NOTE: NO ERROR CHECKING ON MAX (WHICH IS 10,000)

    # Bulk fetch articles in XML format.
    # See http://www.ncbi.nlm.nih.gov/entrez/query/static/efetchlit_help.html
    print "Fetching from remote database...\n";
    my $efetch_id = "$utils/efetch.fcgi?" .
                    "rettype=full&retmode=xml" .
                    "&db=pubmed&query_key=$QueryKey&WebEnv=$WebEnv";
    my $efetch_result = get($efetch_id);

    # Process the results.
    print "Processing...\n";

    # Split into individual articles
    # http://xmltwig.com/xmltwig/tutorial/yapc_twig_s5.html

    my $twig = new XML::Twig( twig_handlers => { PubmedArticle => \&insert_row}); # the insert_row function will be called every time a PubmedArticle element is processed
    $twig->parse($efetch_result);
    # The alternative, rather than defining a handler and then parsing the result,
    # would be to parse the result exactly as above, and then use
    # 	foreach my $article ($root->children('PubmedArticle')) { ... do stuff with $article ... }
    print "Finished for that query.\n";
}


# Handler called by twig processor
sub insert_row {
    my ($twig, $article) = @_; # twig is the whole twig; article is the element being processed
    
    # To see a sample, article, look at e.g. http://www.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=18425025&retmode=xml
    
    my $pmid = $article->first_descendant('PMID')->text;
    print "Processing article $pmid...\n";
#    my $creationyear = $article->first_descendant('DateCreated')->first_descendant('Year')->text;
#    my $publicationyear = $article->first_descendant('PubDate')->first_child->text;
    my $title = $article->first_descendant('ArticleTitle')->text;
#    my $journal = $article->first_descendant('MedlineTA')->text;
    
#    my $volume = "";
#    if ($article->first_descendant('Volume')) {
#    	$volume = $article->first_descendant('Volume')->text;
#    }
#    my $pages = "";
#    if ($article->first_descendant('MedlinePgn')) {
#	$pages = pagenumbers($article->first_descendant('MedlinePgn')->text);
#   }
    my $abstract = ""; # default if we can't find one
    foreach my $abstractnode ($article->first_descendant('AbstractText')) {
    	# for some reason, we're getting here even on articles with no abstract, e.g. PMID 11105652
    	# So we'll try to defend against it with another if...
    	if ($abstractnode) {
    		$abstract = $abstractnode->text;
    	}
    }
#     my $doi = ""; # default if we can't find one
#     foreach my $articleid ($article->descendants('ArticleId')) {
#     	if ($articleid->att("IdType") eq "doi") {
#     		$doi = $articleid->text;
#     	}
#     }
    my @authorlist;
	foreach my $author ($article->descendants('Author')) {
    	# some authors have <CollectiveName>; most don't
    	if ($author->first_child('LastName') && $author->first_child('Initials')) {
			push(@authorlist, $author->first_child('LastName')->text . " " . $author->first_child('Initials')->text);
		}
	}
	my $authors = "";
	for (my $loop=0; $loop < @authorlist; ++$loop) {
	  $authors .= $authorlist[$loop];
	  if ($loop < (@authorlist - 1)) {
	  	$authors .= ", ";
	  }
	}
	my $authorsbrief = substr($authors, 0, 250); # create truncated version of authors (we can't sort on a memo field)

	# debugging: print
	 print "RECORD: $pmid $authors $title\n\n";
	 
	#print "RECORD: $pmid $authors $creationyear $publicationyear $title $journal $volume $pages $doi\n\n";
	
}

# sub pagenumbers { # Convert page format e.g. "2499-501" to "2499-2501"
#   my $beginning = shift;
#   
#   if ($beginning =~ m/(\d+)-(\d+)/) {
#   	my $startpage = $1;
#   	my $endpage = $2;
#   	if (length($endpage) >= length($startpage)) return $beginning;
#   	my $newend = substr($startpage, 0, length($startpage)-length($endpage)) . $endpage;
#   	return $startpage . "-" . $newend;
#   } else {
#     # Doesn't match that format
#     return $beginning;
#   }
# }