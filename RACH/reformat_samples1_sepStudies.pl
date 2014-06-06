#!/usr/bin/perl 

use strict;
use Tk;
use Cwd;


my %rest;
my $main = new MainWindow;
my $project_number;
my $studycount = 0;
$main->Label(-text => 'NAUTILUS PROJECT LOGGIN',
	     -foreground => 'red',
	     -height => 3,
	     -width => 3,
	     -borderwidth => 10,
	     -relief => 'groove',
	    )->pack (-fill => 'both');
    
my $top_frame = $main->Frame(#-label => "PROJECT TO PROCESS", 
			     -relief => 'groove', 
			     #-labelPack => [-foreground => 'purple'],
			     -borderwidth => 10, 
			     -width => 20, 
			     -height => 10)->pack (-ipadx => 40);


my $label1 = $top_frame->Label(-text => "PROJECT TO PROCESS",
			       -foreground => 'red',
			       #-height => 2, 
			      )->pack (-padx => 2, -pady =>2);




my $label1 = $top_frame->Label(-text => "Please select the project to loggin",
			       -foreground => 'purple',
			       #-height => 2, 
			      )->pack (-padx => 2, -pady =>2);


$top_frame->Button(-text => 'Project Selector',
		   -foreground => 'purple',
                   -command => \&open_directory,
		   -relief => 'groove',
		   -borderwidth => 10,
		   -activebackground => 'purple',
		  )->pack;



my $outputgl_frame = $main->Frame(#-label => "SEARCH OPTIONS", 
				     -relief => 'groove', 
				     -borderwidth => 10,
				     -width => 10,
				     -height => 20,
				    )->pack (-ipadx => 40, -fill => 'both'); 


my $label5 = $outputgl_frame->Label(-text => "NUMBER_OF_REPLICATE_GROUPS:",
			       -foreground => 'blue',
			       #-height => 2, 
			      )->grid ("-");

my $no_replicate_groups;
$outputgl_frame->Label (-foreground => 'dark green') -> grid
  ($outputgl_frame->Entry(-textvariable => \$no_replicate_groups));









my $analysis = $main->Button(-text => "SELECT REPLICATE GROUPS", 
			     -command => [\&select_replicategroups],
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







MainLoop;



#GUI SUBROUTINES

#######################
#GET FILES TO PROCESS
#######################


=head2 open_directory

  Title  :  open_directory
  Usage  :  open_directory
  Function : Pops up file selector window; can select multiple files
  Returns : stores list of files selected in @files

=cut



my $file;
my $fs;
sub open_directory {


$fs = $main->FileSelect
    (-directory        => Cwd::cwd(), # Alias: -initialdir
     #-initialfile      => "fileselect.pl",
     -filter           => "*.txt",
     #-foreground => 'purple',
     #-regexp           => '.*\.pl$', #' does not work (?)
     -filelabel        => "Or enter file name:",
     -filelistlabel    => "Files",
     -dirlabel         => "Path",
     -dirlistlabel     => "Directories",
     -width => 30,
     #-height => 25,
     
     -verify           => ['-T'], # accept only text files
     -selectmode => 'single',
 
    );



#print $fs->Show;
$file = $fs->Show;
#print "FILE: $file\n";
#foreach my $i (@files) {
#print "file(s) selected: $i \n";
#}
#print "\n";


}




#main section of script



sub select_replicategroups {



    my @samples;
    my @paired_with;
    my %pair_info;
    my @buttons;
    my @replicate_groups;
    my $project_number;
    my $tube_number;

    open (FILE, "<$file") || die "cannot open $file $! \n";

  PROJECT_LOOP:  while (<FILE>) {
	
	chomp;

    my @info = split(/\t/, $_);
	unless ($info[0] =~ /P1\d+/) {
	    next;
	}
       $project_number = shift @info;
       $tube_number = $info[0];
	#print "TUBE_NUMBER: $tube_number\n";

	my $restinfo = join("\",\"", @info);
	$rest{$tube_number} = $restinfo;
	

	if ($tube_number =~ /\b[0-9]\b/) {
	    my $add = 0;
	    $add .= $tube_number;
	    $tube_number = $add;
	}

    system ("touch $tube_number.tmp");	
	
    next PROJECT_LOOP;

    }


    my $outputfile = $project_number . "_loginFile";
    open (OUTPUT_FILE, ">>$outputfile") || die "Cannot open $outputfile $! \n";
    print OUTPUT_FILE "Begin Project\n";
    print OUTPUT_FILE "\"External_Ref\",\"Workflow_Name\",\"Description\"\n";
    print OUTPUT_FILE "\"$project_number\",\"\",\"Test\"\n";
    print OUTPUT_FILE "End Project\n";
    print OUTPUT_FILE "\n";

	




    for (my $count =1; $count <=$no_replicate_groups; $count++) {
	push @replicate_groups, $count;
    }


    #print "REPLS: @replicate_groups\n";
   # open (FILE, "<$file") || die "cannot open $file $! \n";

  #REPLICATE_LOOP:  while (<FILE>) {
	
	#chomp;

    
	    my $repframe = $main->Toplevel();
	    $repframe->title("REPLICATEGROUPS");
            $repframe->Label(-text => "Select samples for each replicate group",
		       -foreground => 'red',
		       )->pack();




	    foreach  my $s (@replicate_groups) {
		my $text = "select samples for replicate group" . $s;
	    $repframe->Button(-text=>"$text",
			      -foreground=>'purple',
			       -command=>\&open_sample_selector,
			      )->pack (-side => 'top');

	    }


    $repframe->Button(-text => 'Finished',
              -command => sub{exit},
	      -cursor => 'man',
             )->pack (-side => 'bottom', -fill => 'x') ;












my @samples;
sub open_sample_selector {
    
    #my $group = @_;
    #print "$group \n";
    #my $title = "select samples for replicate group" . $i;
    my $samples = $repframe->FileSelect
	(-directory        => Cwd::cwd(), # Alias: -initialdir
	#-initialfile      => "fileselect.pl",
	-filter           => "*.tmp",
	#-foreground => 'purple',
	#-regexp           => '.*\.pl$', #' does not work (?)
	-filelabel        => "Or enter file name:",
	-filelistlabel    => "Files",
	-dirlabel         => "Path",
	-dirlistlabel     => "Directories",
	-width => 30,
	#-height => 25,
     
	#-verify           => ['-T'], # accept only text files
	-selectmode => 'multiple',
 
	);
    
    my %group_samples;
    my $group_no = shift @replicate_groups;
my $group = "group_" . $group_no;	
@samples = $samples->Show;
foreach my $i (@samples) {
    system ("rm $i");
    if ($i =~ /(\d+.tmp)/) {
	$i = $1;

	#print "TEST I: $i\n";
    #$i =~ s/[\/\A-Z\/]+//g;
    push @{$group_samples{$group}}, $i; 
}



   


}

    my @sams;
    
foreach my $x (keys %group_samples) {
    $studycount++;
    my $study_ref = $project_number . "_RepGroup_" . $studycount;

    my $outputfile2 = $study_ref;
    open (OUTPUTFILE2, ">>$outputfile2") || die "cannot open $outputfile2 $! \n";

	print OUTPUTFILE2 "Begin Study\n";
	print OUTPUTFILE2 "\"External_Ref\",\"Workflow_Name\",\"Study_Ref\",\"Project_Ref\",\"Description\",\n";
	print OUTPUTFILE2 "\"$study_ref\",\"test_workflow\",\"\",\"$project_number\",\"\",\n";
	print OUTPUTFILE2 "End Study\n";
	print OUTPUTFILE2 "\n";
	print OUTPUTFILE2 "Begin Sample\n";
	print OUTPUTFILE2 "\"External_Ref\",\"Workflow_Name\",\"Study_Ref\",\"SDG_Ref\",\"U_Tube_Number\",\"U_PairWith\",\"U_Contact_name\",\"U_Contact_E-mail\",\"U_Pi\",\"U_External_Exp_Name\",\"U_TubeLabel\",\"U_Genotype\",\"U_DevStage\",\"U_Tissue\",\"U_Amount_Tissue2\",\"U_Est_RNA\",\"U_Tissue_Mass\",\"U_Homogenized\",\"U_Trizol_Volume\"\n";


	@sams = @{$group_samples{$x}};
     		 foreach my $i (@sams) {
		     print "TEST3 I: $i\n";
		     $i =~ s/^0//;
		     $i =~ s/.tmp//;
		     print "TEST2 I: $i\n";
		     
	#print OUTPUT_FILE "$x: @{$group_samples{$x}}\n";
	print OUTPUTFILE2 "\"$project_number\",\"test_workflow\",\"$study_ref\",\"\",\"$rest{$i}\"\n";
	

		 }
	print OUTPUTFILE2 "End Sample\n";
	print OUTPUTFILE2 "\n";


    

}



}


}



MainLoop;
