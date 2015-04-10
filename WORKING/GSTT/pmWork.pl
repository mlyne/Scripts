#!/usr/bin/perl -w

use strict;
use warnings;
use utf8;
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

open(IFILE, "< $termFile") || die "cannot open $termFile: $!\n";
open(OUT_FILE, "> $outFile") || die "cannot open $outFile: $!\n";
binmode(OUT_FILE, 'utf8');

# Get local time and write to file
my $stamp = DateTime->now( time_zone => 'Europe/London' );
print OUT_FILE "# ", $stamp->dmy, "\t", $stamp->hms, "\n";

my $pubFile = $ARGV[0];

open(IFILE, "< $pubFile") || die "cannot open $pubFile: $!\n";

$/ = undef;

my @entries;

while (<IFILE>)
{
  @entries = split(/\n\n/, $_);
}


# Close the file we've opened
close(IFILE);

$/ = "\n";

foreach my $entry (@entries)
{
#  next unless $entry =~ m/TY  - JOUR/;
 
  my @lines = split("\n", $entry);
  s/\?s/\'s/ for @lines;
  
  # Publication type
  my @type = grep /^M1  - /, @lines;
  s/M1  - // for @type;
  next unless $type[0] =~ m/Article/;
 
  # Process Title
  my @title_lines = grep /^T\d  - /, @lines;
  s/T\d  - // for @title_lines;
 
  # Authors
  my @auth_lines = grep /^AU  - /, @lines;
  s/AU  - // for @auth_lines;
  my @auth_last = @auth_lines;
  s/,.+// for @auth_last;
  
  # Journal title
  my @jo = grep /^JO  - /, @lines;
  s/JO  - // for @jo;
  my $journal = $jo[0];
  
  # DOI
  my @do = grep /^DO  - /, @lines;
  s/DO  - // for @do;
  my $doi = ($do[0]) ? "$do[0]" : "no doi";
  
  # Citation info
  my @py = grep /^PY  - /, @lines;
  s/PY  - // for @py;
  my $date = $py[0];
  $date =~ /(\d+)\/.+/;
#  my $year = ($1) ? ($date) : "no year";
  my $year = ($1) ? ($1) : $date if ($date);
  $year = "no year" unless $year;
  
  my @is = grep /^IS  - /, @lines;
  s/IS  - // for @is;
  my $issue = ($is[0]) ? "$is[0]" : "no issue";
  
  my @vl = grep /^VL  - /, @lines;
  s/VL  - // for @vl;
  my $volume = ($vl[0]) ? "$vl[0]" : "no vol";
  
  my @sp = grep /^SP  - /, @lines;
  s/SP  - // for @sp;
  my $start_page = $sp[0];
  
  my @ep = grep /^EP  - /, @lines;
  s/EP  - // for @ep;
  my $end_page = $ep[0];
  
  my $pp;
  if ($start_page and $end_page) {
    $pp = ($end_page >= $start_page) ? "$start_page" . "-" . "$end_page" : "$start_page";
  } elsif ($start_page) {
    $pp = $start_page;
  }
  
  my $citation = ($pp) ? "$issue\($volume):$pp" : "$issue\($volume)";

  my $query;
  if (($doi) && ($doi !~ /no doi/)) {
    $query = "$doi\[doi\]";
  
    my $attempt1 = pubmed_fetch_records(\$query);
  
    if ($attempt1) {
      say $attempt1;
      next;
    } else {
      say "Move along - nothing to see here!";
    } 
  }
  
  $query = "\"$title_lines[0]\"\&field=title";
  
  my $attempt2 = pubmed_fetch_records(\$query);
 
 if ($attempt2) {
    say $attempt2;
    next;
  } else {
    say "Move along - nothing to see here!";
  }
  
#   say "start";
#   say join("; ", @title_lines);
#   say join("; ", @auth_lines);
#   say $journal, " ($year)", " $citation";
#   say $doi;
#   print join("\[au\] AND ", @auth_last), "\[au\]\n";
#   say "end";
}


# # my ($id, $terms); 
# # while (<IFILE>) 
# # {
# # 
# #   chomp;
# #   ($id, $terms) = split(/\t/, $_);
# # #  my $query = "$terms" . " AND 2008:2012[dp] NOT review[pt]"; # with date encoded
# #   my $query = "$terms" . " NOT review[pt]"; # No date restrictiopn - add in searchTerm file
# # 
# #   pubmed_fetch_records(\$query);
# #   
# #   print $id, "\n";
# # 
# #   print "--- END $id ---\n\n";
# # #  print OUT_FILE "--- END $id ---\n\n";
# #   
# # }

#close (IFILE);
close (OUT_FILE);

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $current_year = $year+1900;

print "FINISHED.\n";
exit;

#####################################################

sub pubmed_fetch_records {
    my $qRef = shift;
    my $query = $$qRef;

    my $utils = "http://www.ncbi.nlm.nih.gov/entrez/eutils";
    my $db = "pubmed";
    my $tool = "&tool=pm2authAddr";
    my $email = "&email=mlyne.careers\@gmail.com";

    # Search for IDs of articles matching query.
    print "SEARCHING REMOTE DATABASE WITH QUERY: $query\n";
    my $esearch = "$utils/esearch.fcgi?" . 
                 "db=$db&retmax=1&usehistory=y&term=";
    my $esearch_result = get($esearch . $query . $tool . $email);
    $esearch_result =~ m|<Count>(\d+)</Count>.*<QueryKey>(\d+)</QueryKey>.*<WebEnv>(\S+)</WebEnv>|s;
    my $Count    = $1;
    my $QueryKey = $2;
    my $WebEnv   = $3;
    
    print "Number of records found: $Count\n";
    
    return unless $Count;
    
    ### apply thresholds to publications returned ###
    
#    if ($Count >250) {
### was 1000
    if ($Count >1) {
     print "More than one Publication found: $Count\n";
     return;
    }
    
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

    my $twig = new XML::Twig( twig_handlers => { PubmedArticle => \&process_pm}); # the process_pm function will be called every time a PubmedArticle element is processed
    $twig->parse($efetch_result);

    print "Finished for that query.\n";
}


# Handler called by twig processor
sub process_pm {
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
    if (!$year) {
      my $dateString = $pub_date->first_descendant('MedlineDate')->text if ( $pub_date->first_descendant('MedlineDate') );
      $dateString =~ /(\d+) .+/;
      $year = $1 if ($1);
    }
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
    
    push( @authorlist, $author_data);
    }
		
    my $authors = "";
    for (my $loop=0; $loop < @authorlist; ++$loop) {
	$authors .= $authorlist[$loop];
	
	if ($loop < (@authorlist - 1)) {
	  	$authors .= ", ";
	}
    }
    
    $twig->purge;
    
	# debugging: print
    my $pmEntry = "$pmid\n$title\n$journal_abbr:$year:$vol_issue:$pages\n$addr\n$authors";
    say OUT_FILE $pmEntry;
	
}
