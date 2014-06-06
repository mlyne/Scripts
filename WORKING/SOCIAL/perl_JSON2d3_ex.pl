#!/usr/bin/perl

use 5.010; # Enable 'say'. Sorry, old perl
use strict;
use warnings;
use JSON::PP; # Just 'use JSON;' on most systems

# 0. set up some data in adjacency table
my %name;
$name{'10.120.5.1'}{'10.120.5.2'}++;
$name{'10.120.5.2'}{'10.120.5.1'}++;

$name{'10.120.5.2'}{'10.120.5.3'}++;
$name{'10.120.5.3'}{'10.120.5.2'}++;

$name{'10.120.5.3'}{'10.120.5.4'}++;
$name{'10.120.5.4'}{'10.120.5.3'}++;

$name{'10.120.5.3'}{'10.120.6.1'}++;
$name{'10.120.6.1'}{'10.120.5.3'}++;

$name{'10.120.5.3'}{'10.120.6.2'}++;
$name{'10.120.6.2'}{'10.120.5.3'}++;

$name{'10.120.5.3'}{'10.120.6.3'}++;
$name{'10.120.6.3'}{'10.120.5.3'}++;


# 1. set up helper structures
# pick a starting point
(my $root) = keys %name;

# empty structures
my %nodes = ();
my %tree  = ();
my @queue = ($root);

# 2. First pass: BFS to determine child nodes 
list_children(\%name, \@queue, \%nodes) while @queue;

# 3. Second pass: DFS to set up tree
my $tree = build_tree($root, \%nodes);

# 4. And use JSON to dump that data structure
my $json = JSON::PP->new->pretty; # prettify for human consumption

say $json->encode($tree);

sub list_children {
  my $adjac = shift;
  my $queue  = shift;
  my $nodes  = shift;

  my $node = shift @$queue;

  # all child nodes
  my @children = keys %{$adjac->{$node}};

  # except the ones we visited earlier, to avoid loops
  @children = grep { ! exists $nodes->{$_}} @children;

  $nodes->{$node} = \@children;

  # and toss on the queue
  push @$queue, @children;
}

sub build_tree {
  my $root  = shift;
  my $nodes = shift;

  my @children;
  for my $child (@{$nodes->{$root}}) {
    push @children, build_tree($child, $nodes);
  }

  my %h = ('name'     => $root,
           'children' => \@children);

  return \%h;
}