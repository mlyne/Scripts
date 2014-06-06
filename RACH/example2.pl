
my $outputgl_frame = $main->Frame(#-label => "SEARCH OPTIONS", 
				     -relief => 'groove', 
				     -borderwidth => 10,
				     -width => 10,
				     -height => 20,
				    )->pack (-ipadx => 40, -fill => 'both'); 


my $label5 = $outputgl_frame->Label(-text => "NUMBER_OF_REPLICATE_GROUPS:",
			       -foreground => 'purple',
			       #-height => 2, 
			      )->grid ("-");

my $no_replicate_groups;
$outputgl_frame->Label (-foreground => 'dark green') -> grid
  ($outputgl_frame->Entry(-textvariable => \$no_replicate_groups));

