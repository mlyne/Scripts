#!/usr/bin/perl -w

use strict;
use Tk;
require Tk::FileSelect;
use Cwd;
use LWP;

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


$top_frame->Label(-text => "FILES TO PROCESS",
			       -foreground => 'purple',
			       #-height => 2, 
			      )->pack (-padx => 2, -pady =>2);


$top_frame->Label(-text => "Please select files for processing:",
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


$checkbutton_frame->Label(-text => "USER OPTIONS:",
			       -foreground => 'dark green',
			       #-height => 2, 
			      )->pack (-padx => 2, -pady =>2);

$checkbutton_frame->Checkbutton(-text => "Enter Customer code & Passwd (Required)",
						 -foreground => 'dark green',
						 -selectcolor => 'dark green',
						 -highlightcolor => 'dark green',
						 #-variable => \$mask,
						 #-anchor => 'w',
						 -command => [\&passwd]
						)->pack(-side => 'top', -expand => 1, -anchor => 'w');
						
#my $mask = 0;
$checkbutton_frame->Checkbutton(-text => "Add User Identifier? (Recommended)",
						 -foreground => 'dark green',
						 -selectcolor => 'dark green',
						 -highlightcolor => 'dark green',
						 #-variable => \$mask,
						 #-anchor => 'w',
						 -command => [\&user]
						)->pack(-side => 'top', -expand => 1, -anchor => 'w');
						


my $analysis = $main->Button(-text => "Process File", 
			     -command => [\&Process],
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

my $ofile;
my ($code, $pass, $code_var, $pas_var);
my ($entry1, $entry2, $var, $var2);


###### FILE OPEN ######
sub open_directory {

$ofile = $main->getOpenFile(-defaultextension => ".txt",
		      -filetypes        =>
		      [
		       ['Text Files',       ['.txt', '.text']],		       		       		       
		       ['All Files',        '*',             ],
		      ],
		      
		      -initialdir       => Cwd::cwd(),
		      #-initialfile      => "getopenfile",
		      -title            => "PMID File Open",
		     ),
		     
}

###### FILE SAVE ######

sub Save
{

			$main->getSaveFile(-defaultextension => ".txt",
		      -filetypes        =>
		      [['Text Files',       ['.txt', '.text']],		     
		       ['All Files',        '*',             ],
		      ],
		      
		      -initialdir       => Cwd::cwd(),
		      #-initialfile      => "getopenfile",
		      -title            => "Save File",
		     ),
}

###### CUSTOMER CODE & PASSWD ######
sub passwd {

#my $main2 = new MainWindow;
my $main2 = $main->Toplevel();

$code_var = "Your Code eg. xx-xxxx";
$pas_var = "xxxxx";

$main2->Label(-text => 'Library Account Information',
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
				    		     
$frame->Label(-text => "Enter BLib Customer Code eg. 99-0999",
			       -foreground => 'blue',
			       #-height => 2, 
			      )->grid ("-");

my $ID = $frame->Label (-foreground => 'dark green') -> grid
  ($code = $frame->Entry(-textvariable => \$code_var));
  
  
  
my $frame2 = $main2->Frame(#-label => "SEARCH OPTIONS", 
				     -relief => 'groove', 
				     -borderwidth => 10,
				     -width => 10,
				     -height => 20,
				    )->pack (-ipadx => 40, -fill => 'both'); 	
				    		     
$frame2->Label(-text => "Enter Password",
			       -foreground => 'purple',
			       #-height => 2, 
			      )->grid ("-");

my $number = $frame2->Label (-foreground => 'dark green') -> grid
  ($pass = $frame2->Entry(-textvariable => \$pas_var,
  								-show => '*'));
             

$main2->Button (-text => "OK",
	     -foreground => 'blue',
	     -command => sub {$main2->withdraw})->pack();

$main2->waitWindow();
            
}

###### USER ID and START COUNT ######
sub user {

#my $main2 = new MainWindow;
my $main2 = $main->Toplevel();

$var = "Arak";
$var2 = "0001";

$main2->Label(-text => 'User Identification',
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
				    		     
$frame->Label(-text => "Enter a user ID eg. mlyne",
			       -foreground => 'blue',
			       #-height => 2, 
			      )->grid ("-");

my $ID = $frame->Label (-foreground => 'dark green') -> grid
  ($entry1 = $frame->Entry(-textvariable => \$var));
  
  
  
my $frame2 = $main2->Frame(#-label => "SEARCH OPTIONS", 
				     -relief => 'groove', 
				     -borderwidth => 10,
				     -width => 10,
				     -height => 20,
				    )->pack (-ipadx => 40, -fill => 'both'); 	
				    		     
$frame2->Label(-text => "Enter a start number (default is 0001)",
			       -foreground => 'purple',
			       #-height => 2, 
			      )->grid ("-");

my $number = $frame2->Label (-foreground => 'dark green') -> grid
  ($entry2 = $frame2->Entry(-textvariable => \$var2));
             

$main2->Button (-text => "OK",
	     -foreground => 'blue',
	     -command => sub {$main2->withdraw})->pack();

$main2->waitWindow();
            
}

###### WARNINGS ######
sub num_warn
{
my $number = shift;

my  $warn1 = $main->Toplevel();
  $warn1->title("!!! You Goofed !!!");
  $warn1->Label(-text => "** Hmmm... It's people like you that give Users a bad name! **",
		       -foreground => 'purple',
		       )->pack;		       
  $warn1->Label(-text => "Which part of NUMBER didn't you understand?!?!",
			     -anchor => 'c',
                             -foreground => 'purple'
               )->pack;
  $warn1->Label(-text => "Does \"$number\" look like a number to you? Don't answer that!",
			     -anchor => 'c',
                             -foreground => 'purple'
			    )->pack;
  $warn1->Label(-text => "Click \"Derr!\" to enter it again then click \"Process File\"",
			     -anchor => 'c',
                             -foreground => 'red',
		        )->pack;



   $warn1->Button (-text => "Derr!",
    -foreground => 'red',
    -command => sub {$warn1->withdraw;
		     user();
    })->pack();  
    
$warn1->waitWindow;

}

sub input_warn
{
my  $warn2 = $main->Toplevel();
  $warn2->title("!!!REMINDER!!!");
  $warn2->Label(-text => "**Hmmm... You may want to give me an input file of PMIDs to Process**",
		       -foreground => 'purple',
		       )->pack;
  $warn2->Label(-text => "Just a thought... I mean, what do I know?",
			     -anchor => 'c',
                             -foreground => 'purple'
			    )->pack;
  $warn2->Label(-text => "Click \"Derr!\" to select an input File",
			     -anchor => 'c',
                             -foreground => 'red',
		             )->pack;



   $warn2->Button (-text => "Derr!",
    -foreground => 'red',
    -command => sub {$warn2->withdraw;
		     open_directory();
    })->pack();  
    
$warn2->waitWindow;

}

sub file_warn
{
my $file = shift;

my  $warn3 = $main->Toplevel();
  $warn3->title("!!! We've Gone a Bit Pete Tong !!!");
  $warn3->Label(-text => "** Not sure what's wrong but there's a problem with $file **",
		       -foreground => 'purple',
		       )->pack;
  $warn3->Label(-text => "Please check it and start again",
			     -anchor => 'c',
                             -foreground => 'purple'
			    )->pack;
  $warn3->Label(-text => "Click \"Oops!\" to EXIT",
			     -anchor => 'c',
                             -foreground => 'red',
		             )->pack;
		             
   $warn3->Button(-text => 'Oops!',
              -command => sub{exit},
	      -cursor => 'man',
             )->pack (-side => 'bottom', -fill => 'x') ;
   
#$warn3->waitWindow;

}

sub pmid_warn
{

my $file = shift;

my  $warn4 = $main->Toplevel();
  $warn4->title("!!! Houston, We Have a Problem !!!");
  $warn4->Label(-text => "** $file doesn't look like a file of PMIDs **",
		       -foreground => 'purple',
		       )->pack;
  $warn4->Label(-text => "Please check the contents or select a new input file",
			     -anchor => 'c',
                             -foreground => 'purple'
			    )->pack;
  $warn4->Label(-text => "Click \"Derr!\" to select a new input File or \"Skidaddle!\" to exit",
			     -anchor => 'c',
                             -foreground => 'red',
		             )->pack;

   $warn4->Button (-text => "Derr!",
    -foreground => 'red',
    -command => sub {$warn4->withdraw;
		     open_directory();
    })->pack();  
    
    $warn4->Button(-text => 'Skidaddle',
     -command => sub{exit},
     -foreground => 'blue',
	 -cursor => 'man',
    )->pack () ;    
    
$warn4->waitWindow;

}


###### FINISHED ######
sub finish
{
my  $finish = $main->Toplevel();
  $finish->title("!!! I'm all done !!!");
  $finish->Label(-text => "** It was lovely working with you... Thank you! **",
		       -foreground => 'purple',
		       )->pack;
  $finish->Label(-text => "You were so much better than the last user",
			     -anchor => 'c',
                             -foreground => 'purple'
			    )->pack;
  $finish->Label(-text => "It is now safe to exit. TTFN",
			     -anchor => 'c',
                             -foreground => 'red',
		             )->pack;



   $finish->Button (-text => "OK",
    -foreground => 'red',
    -command => sub {$finish->withdraw;})->pack();  
    
$finish->waitWindow;

}

###### MAIN SCRIPT ######
sub Process
{

if ( defined($ofile) ) {
	open(OFILE, "< $ofile") || file_warn($ofile);
	} else {
	input_warn();
}

my $lib_code = defined($code) ? $code->get : "*** Code Missing ***";
my $passwd = defined($pass) ? $pass->get : "*** Passwd Missing ***";

my $identifier = defined($entry1) ? $entry1->get : "Arak";
my $number = defined($entry2) ? $entry2->get : "0001";
num_warn($number) if ($number =~ /\D/);
my $count = $number;

my $sfile = Save();
open(SFILE, "> $sfile") || file_warn($sfile);

#print "That's ", $identifier, $number, "!!!\n";

print SFILE $lib_code, "\n", $passwd, "\n\n\n\n\n";

READ_LOOP:while (<OFILE>)
{
  	my $pmid = (/(\d+)/) ? $1 : pmid_warn($ofile);
	#print "PMID $pmid\n";
#chomp(my $pmid = <STDIN>);

	print $pmid, "\n";

	my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=text&db=PubMed&uid=$pmid&dopt=abstract";  

	my $agent    = LWP::UserAgent->new;
	my $request  = HTTP::Request->new(GET => $url);
	my $response = $agent->request($request);
	$response->is_success or die "failed";

	my @ref = split(/\n\n/, $response->content);
	
	if ($ref[1] =~ /Comment in:/) { splice(@ref, 1, 1) };
	if ($ref[2] =~ /^\[Article/) { splice(@ref, 2, 1) };

	my $journ = $ref[0];
	$journ =~ s/\<pre>\n\d+:\s+//;
	my ($jtit, $jdet) = ($journ =~ /^(.+?)(\d.+)\./);
	$jdet =~ s/\. \w.+//;
	$jtit = (length($jtit le 40)) ? $jtit : substr($jtit, 0, 40);
	$jdet = (length($jdet le 40)) ? $jdet : substr($jdet, 0, 40);
	
	my $titl = $ref[1];
	$titl =~ s/^\s+//;
	$titl =~ s/(\[|\])//g;
	$titl =~ s/\n//;
	$titl = (length($titl le 40)) ? $titl : substr($titl, 0, 40);

	my $auth = $ref[2];
	$auth = (length($auth le 40)) ? $auth : substr($auth, 0, 40);




	print SFILE "TXRZ-", $identifier, $count, "\n";
	print SFILE $jtit, "\n";
	print SFILE $jdet, "\n";
#	print SFILE $journ, "\n";
	print SFILE $titl, "\n";
	print SFILE $auth, "\n";
	print SFILE "\n\n\n\n";

#print join("*\n\n", @ref), "\n";

$count++;

}
print SFILE "NNNN\n";
print "I've Finished!\nYou can now EXIT safely :)\n";
finish();
close (OFILE);
close (SFILE);
}


