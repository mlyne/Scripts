#!/usr/bin/perl -w

use strict;

while (<>) {

  print if (/All MeSH Categories/ ... /<\ul>/);

}