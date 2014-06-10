#!/usr/bin/perl -w

use strict;
use warnings;

use Statistics::Suggest;
  
  ## initialize SUGGEST with $data
  my $data = [
    # array of [$user_id, $item_id], ...
    [1, 1], [1, 2], [1, 4], [1, 5],
    [2, 1], [2, 2], [2, 4],
    [3, 3], [3, 4],
    [4, 3], [4, 4], [4, 5],
  ];
  
  my $s = new Statistics::Suggest(
    RType => 2,
    NNbr => 40,
    Alpha => 0.3,
  );
  $s->load_trans($data);
  $s->init;

  ## make top 10 recommendations for $selected_item_ids
  my $rcmds;
  my $selected_item_ids = [1, 2];
  $s->top_n($selected_item_ids, 10, \$rcmds);
  
  print "recommendations: " . join(',', @$rcmds);