#!/usr/bin/perl

use strict;
use warnings;

  # Get a list of the organisms in the database

  use Webservice::InterMine;

  my $service = Webservice::InterMine->get_service('www.flymine.org/query/service');

  print $service->version, "\n";
  my $query = $service->new_query();

  # Specifying a name and a description is purely optional
  $query->name('Tutorial 1 Query');
  $query->description('A list of all the organisms in the database');

  # The view specifies the output columns
  $query->add_view('Organism.name');

  print "Going to get results...\n";
  print $query->url, "\n";
  print $query->results(as => 'string');

  # Also get the taxon-id associated with the organism, and sort by id

  $query->add_view('Organism.taxonId');

  $query->set_sort_order('Organism.taxonId' => 'desc');

  print $query->results(as => 'string');
