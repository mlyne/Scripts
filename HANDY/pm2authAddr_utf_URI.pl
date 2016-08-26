#!/usr/bin/perl -w

use strict;
use warnings;
use utf8;
use URI::Escape;
use open qw(:std :utf8);

use feature ':5.12';

# use TimeCheck;
use LWP::Simple;
use XML::Twig;
use DateTime;

# Print unicode to standard out
binmode(STDOUT, 'utf8');
# Silence warnings when printing null fields
no warnings ('uninitialized');

my $usage = "Usage:pmAuthors.pl termsFile out_file

Format: ID 'tab' Terms
eg. metabDis[TAB](\"metabolic disease\"[tiab] AND 2012:2014[dp])
\n";

unless ( $ARGV[1] ) { die $usage }

my $termFile = $ARGV[0];
my $outFile = $ARGV[1];
my $usrCutoff = ($ARGV[2]) ? $ARGV[2] : 0;

#my $filePrefix = $termFile;
#$filePrefix =~ s/\.txt//;

our (%authCount, %authAddr);
our $cutoff;

open(IFILE, "< $termFile") || die "cannot open $termFile: $!\n";
open(OUT_FILE, "> $outFile") || die "cannot open $outFile: $!\n";
binmode(OUT_FILE, 'utf8');

# Get local time and write to file
my $stamp = DateTime->now( time_zone => 'Europe/London' );
print OUT_FILE "# ", $stamp->dmy, "\t", $stamp->hms, "\n";

my ($id, $terms); 
while (<IFILE>) 
{
#  Time_Check(); # remove for testing;
  %authCount = ();
  %authAddr = ();
  
  chomp;
  ($id, $terms) = split(/\t/, $_);
  my $query = uri_escape("$terms");
#  my $query = "$terms" . " AND 2008:2012[dp] NOT review[pt]"; # with date encoded
#  my $query = "$terms" . " NOT review[pt]"; # No date restrictiopn - add in searchTerm file

  pubmed_fetch_records(\$query, \$terms);
  
  print $id, "\n";
#  print OUT_FILE $id, "\t";
  
  my @highHits = ();
  
  my $keyCnt = scalar(keys (%authCount) );
#  print "keyCnt $keyCnt\n";
  
  my ($total, $meanCnt);
  my %vals =();
  
  
  if ($keyCnt) # if we have authors then...
  {
    while ( my ($key, $val) = each %authCount ) {
      #$total += $val;
      $vals{$val}++; # get paper freq as list of unique vals
    }

    my $rangeCnt = scalar(keys (%vals) ); # get number of unique vals
#    print "rgCnt $rangeCnt\n";
    
    while ( my ($key, $val) = each %vals ) # add unique vals
    { 
      $total += $key;
    }    
    
    $meanCnt = ($total / $rangeCnt); # get mean from unique vals
    $cutoff = $meanCnt;
  
#    print "$total $rangeCnt $cutoff\n"; # print for testing
    
   }

   $cutoff = 0.1 if ($meanCnt < 2);
   $cutoff = $usrCutoff if $usrCutoff;
  
  foreach my $key (sort { $authCount {$b} <=> $authCount {$a} } keys %authCount) 
  { 
    push(@highHits, $key) if ($authCount{$key} > $cutoff);
  }
  
  if (@highHits) {
    foreach my $topAuth (@highHits) {
      print OUT_FILE $id, "\t", $authCount{$topAuth}, "\t", $topAuth, "\tADDR: ", $authAddr{$topAuth}, "\n";
    }
  } else {
      foreach my $key (sort { $authCount {$b} <=> $authCount {$a} } keys %authCount) 
      {
	print OUT_FILE $id, "\t", $authCount{$key}, "\t", $key, "\tADDR: ", $authAddr{$key}, "\n";
      }
  }
    

  print "--- END $id ---\n\n";
#  print OUT_FILE "--- END $id ---\n\n";
  
}

close (IFILE);
close (OUT_FILE);

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $current_year = $year+1900;

# Test searches
# pubmed_fetch_records("(cardinal rn[au] OR everitt bj[au] OR robbins tw[au] OR roberts ac[au]" .
#                      " OR chudasama y[au] OR dickinson a[au] OR winstanley ca[au] OR di ciano p[au]" .
#                      " OR aitken mr[au])" .
#                      " AND (\"2011\"[PDAT] : \"$current_year\"[PDAT])"); # A1. University of Cambridge
# pubmed_fetch_records("(wilkinson l[au] AND cambridge[ad]) AND (\"2011\"[PDAT] : \"$current_year\"[PDAT])"); # A1. University of Cambridge


print "FINISHED.\n";
exit;

#####################################################

sub pubmed_fetch_records {
    my ($qRef, $tRef) = @_;
    my $query = $$qRef;
    my $term = $$tRef;

    my $utils = "http://www.ncbi.nlm.nih.gov/entrez/eutils";
    my $db = "pubmed";
    my $tool = "&tool=pm2authAddr";
    my $email = "&email=mlyne.careers\@gmail.com";

    # Search for IDs of articles matching query.
    print "SEARCHING REMOTE DATABASE WITH QUERY: $term\n";
    my $esearch = "$utils/esearch.fcgi?" . 
                 "db=$db&retmax=1&usehistory=y&term=";
    my $esearch_result = get($esearch . $query . $tool . $email);
    $esearch_result =~ m|<Count>(\d+)</Count>.*<QueryKey>(\d+)</QueryKey>.*<WebEnv>(\S+)</WebEnv>|s;
    my $Count    = $1;
    my $QueryKey = $2;
    my $WebEnv   = $3;
    
    print "Number of records found: $Count\n";
#    print OUT_FILE "Number of records found: $Count\n";
    
    return unless $Count;
##    return; # for testing primary searches
    
    ### apply thresholds to publications returned ###
    
#    if ($Count >250) {
### was 1000
    if ($Count >2000) {
     print "Publication count $Count out of scope (scope: count < 2000)\n";
     return;
    }
    
    ### relaxed thresholds when searching with individual countries
#     if (($Count <= 15) || ($Count >200)) {
#     print "Publication count $Count out of scope (scope: 15 >= count < 200)\n";
#     return;
#     }
    
    # NOTE: NO ERROR CHECKING ON MAX (WHICH IS 10,000)

    # Bulk fetch articles in XML format.
    # See http://www.ncbi.nlm.nih.gov/entrez/query/static/efetchlit_help.html
    print "Fetching from remote database...\n";
    my $efetch_id = "$utils/efetch.fcgi?" .
                    "rettype=full&retmode=xml" .
                    "&db=pubmed&query_key=$QueryKey&WebEnv=$WebEnv";
    my $efetch_result = get($efetch_id);
    
    # PubMed states no more than 3 requests/sec so delay 0.1 sec
    select(undef, undef, undef, 0.4); # default 0.1 s

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
    
    # Gather publication data
    my $journal = $article->first_descendant('Journal') if ( $article->first_descendant('Journal') );
    my $journal_issue = $journal->first_descendant('JournalIssue') if ( $journal->first_descendant('JournalIssue') );
    
    # volume & issue
    my $volume = $journal_issue->first_descendant('Volume')->text if ( $journal_issue->first_descendant('Volume') );
    my $issue = $journal_issue->first_descendant('Issue')->text if ( $journal_issue->first_descendant('Issue') );
    
    my $vol_issue = ($volume) ? ("$volume:$issue") : "no vol or issue";
    
    # Publication year
    my $pub_date = $journal_issue->first_descendant('PubDate') if ( $journal_issue->first_descendant('PubDate') );
    my $year = $pub_date->first_descendant('Year')->text if ( $pub_date->first_descendant('Year') );
    $year = "No Year" if (!$year);
    
    # journal title & abbrev
    my $journal_title = $journal->first_descendant('Title')->text if ( $journal->first_descendant('Title') );
    my $journal_abbr = $journal->first_descendant('ISOAbbreviation')->text if ( $journal->first_descendant('ISOAbbreviation') );
    $journal_abbr = "No Journal" if (!$journal_abbr);
    
    # Pagination
    my $pagination = $article->first_descendant('Pagination') if $article->first_descendant('Pagination');
    my $pages = $pagination->first_descendant('MedlinePgn')->text if ($pagination);
    $pages = "No page info" if (!$pages);

    # Title and Abstract
    my $title = $article->first_descendant('ArticleTitle')->text if $article->first_descendant('ArticleTitle');
    $title = "NO TITLE" if (!$title);

    my $abstract = ""; # default if we can't find one
    foreach my $abstractnode ($article->first_descendant('AbstractText')) {
    	# for some reason, we're getting here even on articles with no abstract, e.g. PMID 11105652
    	# So we'll try to defend against it with another if...
    	if ($abstractnode) {
    		$abstract = $abstractnode->text;
    	} else {
    	$abstract = "NO ABSTRACT";
    	}
    }

    my $addr = "";
#      my $addr = $article->first_descendant('Affiliation')->text;
    if ($article->first_descendant('Affiliation')) {
    	$addr = $article->first_descendant('Affiliation')->text;
    } else {
      $addr = "NO ADDRESS";
    }
    
    my @parts = split(', ', $addr);
    my @revAddr = reverse(@parts);
    my @emailPart = grep (/@/, @parts);
    my @addrNoEmail = grep (!/@/, @parts);
    
    if (@emailPart) 
    {
    $emailPart[0] =~ s/(.+)\. .+/$1/g;
    my $country = $emailPart[0];
    push (@addrNoEmail, $country);
    
    }
    
    $addr = join(', ', @addrNoEmail);

    my @authorlist;
    foreach my $author ($article->descendants('Author')) {
    	# some authors have <CollectiveName>; most don't
    
    my $lastname=$author->first_child('LastName')->text if $author->first_child('LastName');
    my $initials=$author->first_child('Initials')->text if $author->first_child('Initials'); 
    my $collective=$author->first_child('CollectiveName')->text if $author->first_child('CollectiveName');
    my $foreN=$author->first_child('ForeName')->text if $author->first_child('ForeName');
    my $firstN=$author->first_child('FirstName')->text if $author->first_child('FirstName');
    if (!$initials) {  $initials=$foreN || $firstN }
    
    my $author_data = $lastname ." " . $initials if ($lastname && $initials); 
    
    if ((!$lastname) && ($collective)) { 
    $author_data = $collective; 
    } else {
      $lastname = "NO_LAST_NAME";
    }
    
    $authCount{$author_data}++;
    $authAddr{$author_data} = "$addr";
    
    push( @authorlist, $author_data);
    }
#   

#	if ($author->first_child('LastName') && $author->first_child('Initials')) {
#  		push(@authorlist, $author->first_child('LastName')->text . " " . $author->first_child('Initials')->text);
#  	}	
		
    my $authors = "";
    for (my $loop=0; $loop < @authorlist; ++$loop) {
	$authors .= $authorlist[$loop];
	
	if ($loop < (@authorlist - 1)) {
	  	$authors .= ", ";
	}
    }
    
    $twig->purge;
    
#	my $authorsbrief = substr($authors, 0, 250); # create truncated version of authors (we can't sort on a memo field)

	# debugging: print
    print "RECORD: $pmid\n$title\n$journal_abbr:$year:$vol_issue:$pages\n$addr\n$authors\n----\n";
	
}
