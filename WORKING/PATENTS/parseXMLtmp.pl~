#!/usr/bin/perl 
use strict;
use warnings;
use XML::XPath;

my $file = $ARGV[0];
#my $file = "nci.xml";

my $xp = XML::XPath-> new(filename => $file);
open(info,"+>nci.txt");
foreach my $concept ($xp->findnodes('/NCI_PID_XML/Ontology/LabelType')) {

    my $parentid = $concept->getAttribute('id');
    my $type = $concept->getAttribute('name');
    foreach my $LabelValue ( $concept->findnodes('LabelValueList/LabelValue')) {
        my $id =  $LabelValue->getAttribute('id');
        my $name =  $LabelValue->getAttribute('name');
        my $goid =  $LabelValue->getAttribute('GO');

        print info "$parentid\t";
        print info "$type\t";
        print info "$id\t";
        print info "$name\t";
        print info "$goid\n";
    }
}
close info;
