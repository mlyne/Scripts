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
			
			if ($text =~ /MyQuery/)
			{
				$text =~ s/ MyQuery  //;
				print "$text";
			}
			
			if (($text =~ /MeSH Heading/) || ($text =~ /Name of/))
			{
				$text =~ s/ MeSH Heading  //;
				$text =~ s/ Name of Substance  //;
				print "\t$text";
			}

			if ($text =~ /Pharm\. Act/)
			{
				$text =~ s/ Pharm. Action  //;
				print "\t$text";
			}
			if ($text =~ /Note/)
			{
				$text =~ s/ Scope Note  //;
				$text =~ s/ Note  //;
				print "\t$text";
			}
						
		}
		print "\n";
	
	}	
}
