#!/usr/bin/perl

use HTML::TagCloud;

use strict;
use warnings;

require "genesis.pl";

my $cloud = HTML::TagCloud->new;

foreach my $tag (keys %{$tags})
{
  $cloud->add($tag, $tags->{$tag}->{url}, $tags->{$tag}->{count});
}

print $cloud->html_and_css();

