#!/usr/bin/perl -w
use strict;
use HTML::TokeParser::Simple;

my $file = $ARGV[0];
open(FILEO, "< $file") || die "cannot open $file: $!\n";

my @array;
{
 local $/ = '';
 @array = <FILEO>;
}

foreach my $entry (@array)
{
	my @pages = split(/^EOF/m, $entry);
	for my $page (@pages)
	{
		my $p = HTML::TokeParser::Simple->new(\$page);
#		if ($p->get_tag("title"))
#		{
#      		my $title = $p->get_trimmed_text;
#      		print ">> $title\n";
#      	}
      	
      	while (my $token = $p->get_tag("tr"))
      	{
#			my $url = $token->[1]{href} || "-";
			my $text = $p->get_text("/td");
			
			if (($text =~ /MeSH Heading/) || ($text =~ /Name of/))
#			if ($text =~ /Name of/)
			{
				print ">> $text\n";
			}
			if ($text =~ /Scope Note/)
			{
				print "$text\n";
			}
			if ($text =~ /Registry Number/)
			{
				print "$text\n";
			}
			if ($text =~ /Entry Term/)
			{
				print "$text\n";
			}						
			if ($text =~ /Pharm\. Act/)
			{
				print "$text\n";
			}
			if ($text =~ /Note/)
			{
				print "$text\n";
			}
		}
		print "\n\n";
	
	}	
#	print join("***\n\n\n***", @pages);
	
}

#my $p = HTML::TokeParser::Simple->new($file);
#if ($p->get_tag("title")) {
#      my $title = $p->get_trimmed_text;
#      print "Title: $title\n";
#}

#while (my $token = $p->get_tag("tr")) {
#	my $url = $token->[1]{href} || "-";
#	my $text = $p->get_text("/td");
#	if ($text =~ /Pharm\. Act/) {
#		print "$text\n";
#	}
#}



#while ( my $token = $p->get_token ) {
     # This prints all text in an HTML doc (i.e., it strips the HTML)
#     next unless $token->is_text;
#     print $token->as_is;
#}

#my $p = HTML::TokeParser::Simple->new($file);
#while(my $token = $p->get_token) {
#print 'Text: '.$token->as_is."\n" if ($token->is_text);
#print 'Tag: '.$token->as_is."\n" if ($token->is_tag);
#} 
