#!/usr/bin/perl -w

use strict;
 
my $file = $ARGV[0];

#print "88-0619\n6MJYATY\n\n\n\n\n";

open(FILEO, "< $file") || die "cannot open $file: $!\n";

my @array;
{
 local $/ = '';
 @array = <FILEO>;
}

foreach my $entry (@array)
{
	next unless ($entry =~ /^TI/mg);

	$entry =~ s/^(\w\w) /$1$1/mg;
	
#	my @fields = split(/^\w\w   /mg, $entry);
	my @fields = split(/^\w\w/mg, $entry);
	
	my @titl = grep(/^TI/m, @fields);
	$titl[0] =~ s/\s+/ /g if $titl[0];
	$titl[0] =~ s/^\w\w //m if $titl[0];
	if ($titl[0])
	{
	$titl[0] = (length($titl[0] le 40)) ? $titl[0] : substr($titl[0], 0, 40);
	}
	
	my @auth = grep(/^AU/m, @fields);
	
	$auth[0] =~ s/\s+/ /g if $auth[0];
	$auth[0] =~ s/^\w\w //m if $auth[0];
	$auth[0] =~ s/\[(R|r)eprint (A|a)uthor\]//g if $auth[0];
	if ($auth[0])
	{
	$auth[0] = (length($auth[0] le 40)) ? $auth[0] : substr($auth[0], 0, 40);
	}
	
	my @journ = grep(/^SO/m, @fields);
	$journ[0] =~ s/\s+/ /g;
	$journ[0] =~ s/^\w\w //m;
	
	
	my ($jtit, $jref) = $journ[0] =~ /^(.+?), (.+)./;
#	$jtit = (length($jtit le 40)) ? $jtit : substr($jtit, 0, 40);
#	my $jref2 = (length($jref le 40)) ? $jref : substr($jref, 0, 40);
	$jref = substr($jref, 0, 40);
	
	my $titl = ($titl[0]) ? $titl[0] : "No Title";
	my $auth = ($auth[0]) ? $auth[0] : "No Author";
	$jtit = ($jtit) ? $jtit : "No Journal";
	$jref = ($jref) ? $jref : "No Journal Ref";
	
	print lc($jtit), "\n";
#	print $jref, "\n";	
#	print $titl, "\n";
#	print $auth, "\n";
#	print $journ[0], "\n";
		
#	print "\n\n\n\n";
}

#print "NNNN\n";
