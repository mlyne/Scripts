#!/usr/bin/perl

use HTTP::Cache::Transparent;
use LWP::Simple;
use XML::RSSLite;
use Data::Dumper;

use strict;
use warnings;

HTTP::Cache::Transparent::init( {
    BasePath => './cache',
    NoUpdate  => 30*60
  } );

$Data::Dumper::Terse= 1;	# avoids $VAR1 = * ; in dumper output

my $who = shift;
$who = 'jbum' if !$who;
my $delURL = "http://del.icio.us/rss/$who";

print "loading tags...\n";
my $xml = get($delURL);

my %result = ();
my $tags = {};

parseRSS(\%result, \$xml);

foreach my $item (@{$result{'item'}}) 
{
	my $url = $item->{link};
	foreach my $tag (split / /,$item->{'dc:subject'})
	{
		my $utag = uc($tag);
		if (!$tags->{$utag}) {
			$tags->{$utag} = {url=>$url, count=>0, tag=>$tag};
		}
		$tags->{$utag}->{count}++;
	}
}

my $ofilename = "deliciousTags_$who.pl";
open (OFILE, ">$ofilename") or die ("Can't open $ofilename file for $ofilename ");
print OFILE "package mytags;\n\n\$tags = " . Dumper($tags) . ";\n1;\n";
close OFILE;

printf "Wrote %d tags to $ofilename \n", scalar(keys %{$tags});

