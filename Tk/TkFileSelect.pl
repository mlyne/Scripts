#!/usr/bin/perl 

use strict;
use Tk;
use Cwd;




my $main = new MainWindow;



$main->Label(-text => 'BRITISH LIBRARY BATCH ORDER FILE PROCESSING',
	     -foreground => 'red',
	     -height => 3,
	     -width => 3,
	     -borderwidth => 10,
	     -relief => 'groove',
	    )->pack (-fill => 'both');
    
my $top_frame = $main->Frame(#-label => "FILES TO PROCESS", 
			     -relief => 'groove', 
			     #-labelPack => [-foreground => 'purple'],
			     -borderwidth => 10, 
			     -width => 20, 
			     -height => 10)->pack (-ipadx => 60);


my $label1 = $top_frame->Label(-text => "FILES TO PROCESS",
			       -foreground => 'purple',
			       #-height => 2, 
			      )->pack (-padx => 2, -pady =>2);




my $label1 = $top_frame->Label(-text => "Please select files for processing:",
			       -foreground => 'purple',
			       #-height => 2, 
			      )->pack (-padx => 2, -pady =>2);


$top_frame->Button(-text => 'File Selector',
		   -foreground => 'purple',
                   -command => \&open_directory,
		   -relief => 'groove',
		   -borderwidth => 10,
		   -activebackground => 'purple',
		  )->pack;



my $analysis = $main->Button(-text => "Process File", 
			     -command => [\&anal],
			     -relief => 'raised',
			     -cursor => 'mouse',
			     -borderwidth => 10,
			     -foreground => 'red',
			     -activebackground => 'red',
			    )->pack;

$main->Button(-text => 'Exit',
              -command => sub{exit},
	      -cursor => 'man',
             )->pack (-side => 'bottom', -fill => 'x') ;



my $file;
my $fs;
sub open_directory {


$fs = $main->FileSelect
    (-directory        => Cwd::cwd(), # Alias: -initialdir
     -filter           => "*.txt",
     #-regexp           => '.*\.pl$', #' does not work (?)
     -filelabel        => "Or enter file name:",
     -filelistlabel    => "Files",
     -dirlabel         => "Path",
     -dirlistlabel     => "Directories",
     -width => 30,
     
     -verify           => ['-T'], # accept only text files
#     -selectmode => 'multiple',
 
    );



#print $fs->Show;
#@files = $fs->Show;
my $file = $fs->Show;


}



MainLoop;