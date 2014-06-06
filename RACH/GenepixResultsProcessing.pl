#!/usr/bin/perl 

use strict;
#use microarray_data;
use Tk;
use Cwd;

#instantiate object and populate array-hash structure with results file.

#$a = microarray_data -> new();


my $cut_off_counter = 0;



##################################
#GUI SECTION
##################################



my $main = new MainWindow;



$main->Label(-text => 'GENEPIX RESULTS FILE PROCESSING',
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
			     -height => 10)->pack (-ipadx => 40);


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



my $checkbutton_frame = $main->Frame(#-label => "PROCESSING OPTIONS", 
				     -relief => 'groove', 
				     -borderwidth => 10,
				     -width => 10,
				     -height => 20,
				    )->pack (-ipadx => 40, -fill => 'both'); 


my $label1 = $checkbutton_frame->Label(-text => "PROCESSING OPTIONS:",
			       -foreground => 'dark green',
			       #-height => 2, 
			      )->pack (-padx => 2, -pady =>2);



my $mask = 0;
my $mask_check = $checkbutton_frame->Checkbutton(-text => "mask genes?",
						 -foreground => 'dark green',
						 -selectcolor => 'dark green',
						 -highlightcolor => 'dark green',
						 -variable => \$mask,
						 -anchor => 'w',
						 #-command => \&mask
						)->pack(-side => 'top', -expand => 1, -anchor => 'w');






my $cut_off = 0;
my $cut_off_check = $checkbutton_frame->Checkbutton(-text => "Apply cut-offs?",
						    -foreground => 'dark green',
						    -selectcolor => 'dark green',
						    -highlightcolor => 'dark green',
						    -variable => \$cut_off,
						    -anchor => 'w',
						    -command => \&get_values
						   )->pack(-side => 'top', -expand => 1,  -anchor => 'w');


my $diameter = 0;
#my $diameter_check = $checkbutton_frame->Checkbutton(-text => "Apply diameter cut-off (100um)?",
#						     -foreground => 'dark green',
#						     -selectcolor => 'dark green',
#						     -highlightcolor => 'dark green',
#						     -anchor => 'w',
#						     -variable => \$diameter,
#						     #-command => \&get_diam_value
#						    )->pack(-side => 'top', -expand => 1,  -anchor => 'w');



my $average = 0;
#my $average_checkbutton = $checkbutton_frame->Checkbutton(-text => "Average replicates?",
#							  -foreground => 'dark green',
#							  -selectcolor => 'dark green',
#							  -highlightcolor => 'dark green',
#							  -anchor =>'w',
#							  -variable => \$average,
#							  #-command => \&get_diam_value
#							 )->pack(-side =>'top', -expand => 1, -anchor => 'w#');



my $normalisation = 0;
my $normalisation_checkbutton = $checkbutton_frame->Checkbutton(-text => "Apply local normalisation, NO AVERAGING?",
								-foreground => 'dark green',
								-selectcolor => 'dark green',
								-highlightcolor => 'dark green',
								-variable => \$normalisation,
								-anchor => 'w',
								-command => \&get_window_value
							       )->pack(-side =>'top', -expand => 1, -anchor => 'w');

my $labelOR = $checkbutton_frame->Label(-text => "OR:",
			       -foreground => 'dark green',
			       #-height => 2, 
			      )->pack (-anchor => 'w');


my $normalisation_averaging = 0;
my $normalisation_averaging_checkbutton = $checkbutton_frame->Checkbutton(-text => "Apply local normalisation, WITH AVERAGING?",
								-foreground => 'dark green',
								-selectcolor => 'dark green',
								-highlightcolor => 'dark green',
								-variable => \$normalisation_averaging,
								-anchor => 'w',
								-command => \&get_window_value
							       )->pack(-side =>'top', -expand => 1, -anchor => 'w');



my $help1;
my $help = $checkbutton_frame->Button(-text => "HELP",
					 -foreground => 'red',
					 #-variable => \$help1,
					 -command => \&get_help1,
					 -cursor => 'question_arrow',
					 #-selectcolor => 'red',
					 -highlightcolor => 'red',
					 -activebackground => 'red',   
					 -relief => 'raised'
					 )->pack(-anchor => 'e');



my $analysis = $main->Button(-text => "start analysis", 
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





#######################
#GET FILES TO PROCESS
#######################


=head2 open_directory

  Title  :  open_directory
  Usage  :  open_directory
  Function : Pops up file selector window; can select multiple files
  Returns : stores list of files selected in @files

=cut



my @files;
my $fs;
sub open_directory {


$fs = $main->FileSelect
    (-directory        => Cwd::cwd(), # Alias: -initialdir
     #-initialfile      => "fileselect.pl",
     -filter           => "*.gpr",
     #-foreground => 'purple',
     #-regexp           => '.*\.pl$', #' does not work (?)
     -filelabel        => "Or enter file name:",
     -filelistlabel    => "Files",
     -dirlabel         => "Path",
     -dirlistlabel     => "Directories",
     -width => 30,
     #-height => 25,
     
     -verify           => ['-T'], # accept only text files
     -selectmode => 'multiple',
 
    );



#print $fs->Show;
@files = $fs->Show;
foreach my $i (@files) {
print "file(s) selected: $i \n";
}
print "\n";


}


###########################
#GET CUT_OFF VALUES
###########################


=head2 get_values

 Title   : get_values
 Usage   : get_values
 Function: pops up box to enter cut-off values
 Example : 
 Returns : -
 Args    : -

=cut





my $lower_limit_value = 50;
my $upper_limit_value = 95; 
my $upper_limit;
my $lower_limit;
my $bl;
sub get_values {

  if ( ! Exists $bl) {  
$bl = $main->Toplevel();
$bl->title("CUT_OFF VALUES");
my $label1 = $bl->Label(-text => "Please enter the lower cut-off",
                        -foreground => 'dark green',
		       )->pack;
 $lower_limit = $bl->Entry(-textvariable => \$lower_limit_value,
	   
			  )->pack;
my $label2 = $bl->Label(-text => "Please enter the upper cut-off",
		        -foreground => 'dark green',
			)->pack;
 $upper_limit = $bl->Entry(-textvariable => \$upper_limit_value
			   
			  )->pack;


$bl->Button (-text => "OK",
	     -foreground => 'red',
	     -command => sub {$bl->withdraw})->pack();



$bl->waitWindow();

}
else {
  $bl = "";
}
}


###########################
#GET DIAMETER CUT_OFF
###########################



my $diameter_value;
my $diameter_entry;
my $cl;
sub get_diam_value {

  if (! Exists $cl) {
$cl = $main->Toplevel();
$cl->title("DIAMETER CUT_OFF");
my $label1 = $cl->Label(-text => "Please enter the diameter cut_off",
		        -foreground => 'dark green',
		       )->pack;
$diameter_entry = $cl->Entry(-textvariable => \$diameter_value)->pack;

$cl->Button (-text => "close",
	     -foreground => 'red',
	     -command => sub {$cl->withdraw})->pack();


}
else {
  $cl = "";
}
}



##################################
#GET WINDOW FOR NORMALISATION
##################################



my $window_size;
my $window = 16;
my $jl;
sub get_window_value {

  if (! Exists $jl) {
 $jl = $main->Toplevel();
$jl->title("WINDOW SIZE FOR NORMALISATION");
my $label1 = $jl->Label(-text => "Please enter the window size for normalisation",
		        -foreground => 'dark green',
		       )->pack;
$window_size = $jl->Entry(-textvariable => \$window)->pack;

$jl->Button (-text => "OK",
	     -foreground => 'red',
	     -command => sub {$jl->withdraw})->pack();


}

else {
$jl = "";
}

}










###################################
#HELP SECTION
###################################

my $el;

sub get_help1 {


#unless (! Exists $el) {
$el = $main->Toplevel();
$el->title("HELP");


$el->Label(-text => "Please select a help topic:",
	   -foreground => 'red',
	 )->pack();


$el->Button(-text => "general genes",
	    -foreground => 'purple',
	    -command => \&general_help,
	    )-> pack (-side => 'top');


$el->Button(-text => "mask genes",
	    -foreground => 'purple',
	    -command => \&mask_help,
	    )-> pack (-side => 'top');



$el->Button(-text => "Apply cut_offs",
	    -foreground => 'purple',
	    -command => \&cut_off_help,
	    )-> pack (-side => 'top');



$el->Button(-text => "Local normalisation",
	    -foreground => 'purple',
	    -command => \&normalisation_help
	    )-> pack (-side => 'top');


$el->Button (-text => "close",
	     -foreground => 'red',
	     -command => sub {$el->withdraw})->pack();


}     


sub general_help {


my $kl = $el->Toplevel();
$kl->title("GENERAL HELP");


my $average_text = $kl->Scrolled("Text", -scrollbars => 'ose', -width => 90, -height => 30)->pack();

open (FH, "genePixresultsprocessing_generalhelp") || die "could not open average_help";
while (<FH>) {
  $average_text->insert('end', $_);
}
close(FH);


$kl->Button (-text => "close",
	     -foreground => 'red',
	     -command => sub {$kl->withdraw})->pack();

}


sub mask_help {


my $gl = $el->Toplevel();
$gl->title("MASK GENES HELP");


my $mask_text = $gl->Scrolled("Text", -scrollbars => 'ose', -width => 90, -height => 30)->pack();

open (FH, "maskgenes_help") || die "could not open maskgenes_help";
while (<FH>) {
  $mask_text->insert('end', $_);
}
close(FH);


$gl->Button (-text => "close",
	     -foreground => 'red',
	     -command => sub {$gl->withdraw})->pack();



}


sub cut_off_help {


my $hl = $el->Toplevel();
$hl->title("CUT_OFF HELP");


my $cutoff_text = $hl->Scrolled("Text", -scrollbars => 'ose', -width => 90, -height => 30)->pack();

open (FH, "cutoff_help") || die "could not open cutoff_help";
while (<FH>) {
  $cutoff_text->insert('end', $_);
}
close(FH);


$hl->Button (-text => "close",
	     -foreground => 'red',
	     -command => sub {$hl->withdraw})->pack();



}



sub normalisation_help {


my $ll = $el->Toplevel();
$ll->title("NORMALISATION HELP");


my $normalisation_text = $ll->Scrolled("Text", -scrollbars => 'ose', -width => 90, -height => 30)->pack();

open (FH, "normalisation_help") || die "could not open normalisation_help";
while (<FH>) {
  $normalisation_text->insert('end', $_);
}
close(FH);


$ll->Button (-text => "close",
	     -foreground => 'red',
	     -command => sub {$ll->withdraw})->pack();

}

#####################################
#ANALYSIS SECTION
#####################################



sub anal {

#my $rfiles = shift;
#print "@{$rfiles} \n";

my ($second, $minute, $hour, $DayOfMonth, $Month, $year, $weekday, $DayOfYear, $IsDST) = gmtime(time);
my $realmonth = $Month +1;
my $realyear = "01";

#printf('%02d:%02d:%02d %02d/%02d/%02d', $hour, $minute, $second, $DayOfMonth, $realmonth, $realyear);

#my $date = $weekday, " .",  $DayOfMonth, " ." $realmonth, ".", $realyear;
my $date = $DayOfMonth . "_";
$date = $date . $realmonth;
$date = $date . "_" . $realyear;

my $time = $hour . "." . $minute;

#print "date: $date \n";
#print "time: $time \n";

open (REPORT_HANDLE, ">report.$date:$time");

print REPORT_HANDLE "REPORT FOR ";
printf REPORT_HANDLE ('%02d:%02d:%02d %02d:%02d', $DayOfMonth, $realmonth, $realyear, 'at', $hour, $minute), "\n";
print REPORT_HANDLE "========================================";
print REPORT_HANDLE "\n";


#my @index = $files_to_get->curselection();

FILE_LOOP: foreach  my $file (@files) {

#my $file = $files_to_get->get($index);

chomp $file;

print "\n";
print "processing file: $file \n";
print REPORT_HANDLE "\n";
print REPORT_HANDLE "processed file: \n $file \n";
open (RESULTS_HANDLE, $file);
$a -> results_structure(\*RESULTS_HANDLE);

my $output_file = $file . ".output"; 
my $quality_control_file = $file . "_QualityControl";
#my $quality_control_file2 = $file . "_QualityControl2";

print REPORT_HANDLE "output file: \n $output_file \n";
print REPORT_HANDLE "\n";
print REPORT_HANDLE "processes on $file: \n";
print REPORT_HANDLE "\n";





#########################
#APPLY CUT_OFFS
#########################

my $do_cut_offs = 0;
my $l_limit;
my $u_limit;
if ($cut_off == 1) {

$l_limit = $lower_limit->get();

if ($l_limit =~ /\D/ || $l_limit !~ /^[+-]?\d+$/) {

#$cut_off_counter = 0;

my  $warn1 = $main->Toplevel();
  $warn1->title("!!!!!WARNING!!!!!");
  my $label1 = $warn1->Label(-text => "**LOWER_CUT_OFF CONTAINS NON-DIGIT CHARACTERS OR IS NOT AN INTEGER**",
		       -foreground => 'red',
		       )->pack;
  my $label2 = $warn1->Label(-text => "PRESS CLOSE TO ENTER VALUE AGAIN",
			     -anchor => 'c',
                             -foreground => 'red'
			    )->pack;
  my $label3 = $warn1->Label(-text => "PRESS \"START ANALYSIS\" BUTTON TO RESTART",
			     -anchor => 'c',
                             -foreground => 'red',
		             )->pack;



   $warn1->Button (-text => "close",
    -foreground => 'red',
    -command => sub {$warn1->withdraw;
		     $bl = "";
		     get_values();
    })->pack();  
$warn1->waitWindow;
$l_limit = $lower_limit->get();



}


$u_limit = $upper_limit->get(); 



my $upper_limit2;
my $checked;
my $warn2;

if ($u_limit =~ /\D/ || $u_limit !~ /^[+-]?\d+$/) {

#$cut_off_counter = 0;


  $warn2 = $main->Toplevel();
  $warn2->title("!!!!!WARNING!!!!!");
  my $label1 = $warn2->Label(-text => "**UPPER_CUT_OFF CONTAINS NON-DIGIT CHARACTERS OR IS NOT AN INTEGER**",
		       -foreground => 'red',
		       )->pack;
  my $label2 = $warn2->Label(-text => "PRESS CLOSE TO ENTER VALUE AGAIN",
			     -anchor => 'c',
                             -foreground => 'red'
			    )->pack;
  my $label3 = $warn2->Label(-text => "PRESS \"START ANALYSIS\" BUTTON TO RESTART",
			     -anchor => 'c',
                             -foreground => 'red',
		             )->pack;



               $warn2->Button (-text => "close",
	     -foreground => 'red',
	     -command => sub {$warn2->withdraw;
			      $bl = "";
			      get_values();
           })->pack();
$warn2 ->waitWindow();
$u_limit = $upper_limit->get();
} 


$do_cut_offs = 1;
}





#################################
#APPLY LOCAL NORMALISATION
#################################


my $do_normalisation = 0;
if ($normalisation == 1 || $normalisation_averaging == 1) {


my $window = $window_size->get();

if ($window =~ /\D/ || $window !~ /^[+-]?\d+$/) {
  my $warn4 = $main->Toplevel();
  $warn4->title("!!!!!WARNING!!!!!");
  my $label1 = $warn4->Label(-text => "**WINDOW SIZE CONTAINS NON-DIGIT CHARACTERS OR IS NOT AN INTEGER**",
		       -foreground => 'red',
		       )->pack;
  my $label2 = $warn4->Label(-text => "PRESS CLOSE TO ENTER VALUE AGAIN",
			     -anchor => 'c',
                             -foreground => 'red'
			    )->pack;
  my $label3 = $warn4->Label(-text => "PRESS \"START ANALYSIS\" BUTTON TO RESTART",
			     -anchor => 'c',
                             -foreground => 'red',
		             )->pack;




  $warn4->Button (-text => "close",
	     -foreground => 'red',
	     -command => sub {$warn4->withdraw;
			      $jl = "";
			      get_window_value();
			      })->pack();

$warn4->waitWindow;
$window = $window_size->get();

} 


$do_normalisation = 1;

}


if ($mask == 1) {
print "Applying masking.....\n";
print REPORT_HANDLE "Applied masking \n";
$a->masking($quality_control_file);
}

if ($do_cut_offs == 1) {

print "Applying cut_offs......\n";
print REPORT_HANDLE "Applied cut-offs: \n";

print REPORT_HANDLE "lower_cut_off: $l_limit \n";
print REPORT_HANDLE "upper_cut_off: $u_limit \n";

$a->sd_cut_off($u_limit, $l_limit, $quality_control_file);

}


if ($diameter == 1) {

print "Applying diameter cut_offs.....\n";
print REPORT_HANDLE "Applied diameter cut_off: \n";

print REPORT_HANDLE "Diameter cut-off: 100 \n";

$a->diameter_cut_off(100);

}


#$a->quality_control($quality_control_file);
  


if ($average == 1) {
print "Averaging replicates.....\n";
print REPORT_HANDLE "Averaged replicates \n";

open (RESULTS_HANDLE2, $file);

$a->average_replicates(\*RESULTS_HANDLE2);

}

if ($do_normalisation == 1) {
  if ($normalisation == 1) {
print "Doing local normalisation.....\n";
print REPORT_HANDLE "Local normalisation applied \n";
print REPORT_HANDLE "window size used for normalisation: $window \n";
#$window = $window/2;
$a->local_normalisation($window);
}
  elsif ($normalisation_averaging == 1) {
print "Doing local normalisation.....\n";
print REPORT_HANDLE "Local normalisation applied \n";
print REPORT_HANDLE "window size used for normalisation: $window \n";
#$window = $window/2;
$a->local_normalisation_averaging($window, $quality_control_file);
}
}


print REPORT_HANDLE "\n";
print REPORT_HANDLE "####################### \n";
print REPORT_HANDLE "\n";
$a->print_results("$output_file");

next FILE_LOOP;


}
print "Finished, you can now exit\n";
}





MainLoop;




















