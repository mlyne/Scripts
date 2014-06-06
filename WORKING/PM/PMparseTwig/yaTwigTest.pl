#!/usr/bin/perl
use strict;
use warnings;
use XML::Twig;

my $xfile = q(
<XML>  
<name> 
</name> 
<address> 
<p id="1">a b c d </p> 
<p id="2">y y y </p> 
</address> 
</XML> 
);

my $t = XML::Twig->new(
    twig_handlers => { 'address/p' => \&addr}
);
my $pcnt = 0;
my $wcnt = 0;
$t->parse($xfile);
print "Address has $pcnt paragraph tags with $wcnt words.\n";

sub addr {
    my ($twig, $add) = @_;
    my @words = split /\s+/, $add->text();
    $wcnt += scalar @words;
    $pcnt++;
}

__END__
