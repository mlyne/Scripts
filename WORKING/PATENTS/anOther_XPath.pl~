use strict;
use warnings;

use XML::XPath;

my $xp = XML::XPath->new(ioref => *DATA);

my $names = $xp->find('/category/event/@name');

for my $node ($names->get_nodelist) {
  say $node->getNodeValue;
}


__DATA__
  <category name="a">
    <event name="cat1" />  
    <event name="cat2" />  
    <event name="cat3" />  
    <event name="cat4" />  
    <event name="cat5" />  
  </category>

## OUT 
#cat1
#cat2
#cat3
#cat4
#cat5
