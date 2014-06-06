#!/usr/bin/perl 

use strict;
use Tk;
use Cwd;

# WINDOW1
my $main = new MainWindow;

$main->Label(-text => 'Window 1',
	     -foreground => 'blue',
	     -height => 3,
	     -width => 3,
	     -borderwidth => 10,
	     -relief => 'groove',
	    )->pack (-fill => 'both');
	    
my $checkbutton_frame = $main->Frame(#-label => "PROCESSING OPTIONS", 
				     -relief => 'groove', 
				     -borderwidth => 10,
				     -width => 10,
				     -height => 20,
				    )->pack (-ipadx => 40, -fill => 'both'); 


my $label1 = $checkbutton_frame->Label(-text => "USER OPTIONS:",
			       -foreground => 'dark green',
			       #-height => 2, 
			      )->pack (-padx => 2, -pady =>2);


my $mask = 0;
$checkbutton_frame->Checkbutton(-text => "Add User Identifier?",
						 -foreground => 'dark green',
						 -selectcolor => 'dark green',
						 -highlightcolor => 'dark green',
						 -variable => \$mask,
						 #-anchor => 'w',
						 -command => [\&anal]
						)->pack(-side => 'top', -expand => 1, -anchor => 'w');
	    
#my $process = $main->Button(-text => "Process", 
#			     -command => [\&anal],
#			     -relief => 'raised',
#			     -cursor => 'mouse',
#			     -borderwidth => 10,
#			     -foreground => 'red',
#			     -activebackground => 'red',
#			    )->pack;
 
	    

#$main->Button(-text => 'Exit',
#              -command => sub{exit},
#	      -cursor => 'man',
#             )->pack (-side => 'bottom', -fill => 'x') ;
             

 
#anal();
             
#$main2->Button(-text => 'Exit',
 #             -command => sub{exit},
#	      -cursor => 'man',
#             )->pack (-side => 'bottom', -fill => 'x') ;

	
			     
MainLoop;
my ($entry1, $entry2);
my ($var, $var2);


sub anal {

# WINDOW2
	      
my $main2 = new MainWindow;
$var = "Arak";
$var2 = "0001";

$main2->Label(-text => 'Window 2',
	     -foreground => 'red',
	     -height => 3,
	     -width => 3,
	     -borderwidth => 10,
	     -relief => 'groove',
	    )->pack (-fill => 'both');

my $frame = $main2->Frame(#-label => "SEARCH OPTIONS", 
				     -relief => 'groove', 
				     -borderwidth => 10,
				     -width => 10,
				     -height => 20,
				    )->pack (-ipadx => 40, -fill => 'both'); 	
				    		     
$frame->Label(-text => "User ID",
			       -foreground => 'blue',
			       #-height => 2, 
			      )->grid ("-");
#my $entry1;			      
#my $var;
my $ID = $frame->Label (-foreground => 'dark green') -> grid
  ($entry1 = $frame->Entry(-textvariable => \$var));
  
  
  
my $frame2 = $main2->Frame(#-label => "SEARCH OPTIONS", 
				     -relief => 'groove', 
				     -borderwidth => 10,
				     -width => 10,
				     -height => 20,
				    )->pack (-ipadx => 40, -fill => 'both'); 	
				    		     
$frame2->Label(-text => "Starting Number",
			       -foreground => 'purple',
			       #-height => 2, 
			      )->grid ("-");
#my $entry2;			      
#my $var2;
my $number = $frame2->Label (-foreground => 'dark green') -> grid
  ($entry2 = $frame2->Entry(-textvariable => \$var2));
             
               $main2->Button(-text => "OK", 
			     -command => [\&print_out],
			     -relief => 'raised',
			     -cursor => 'mouse',
			     -borderwidth => 10,
			     -foreground => 'red',
			     -activebackground => 'red',
			    )->pack;
             
}

sub print_out
{
my ($ID, $num);
my $ID = $entry1->get;
my $num = $entry2->get;

my $name = defined($ID) ? $ID : "scooby";
my $count = defined($num) ? $num : "doo";

print "Var1= $var; var2=$var2; ID=$ID; num=$num\n";
print "That's ", $name, $count, "!!!\n";

}

#MainLoop;