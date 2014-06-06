#!/usr/bin/perl -w

use strict;
use Tk;
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
			     -command => [\&File],
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

open(FILEO, "< $file") || die "cannot open $file: $!\n";

READ_LOOP:while (<FILEO>)
{
  	my $pmid = (/(\d+)/) ? $1 : die "Not a PMID or Wrong fileformat\nPlease check your file!: $!\n";
	#print "PMID $pmid\n";
#chomp(my $pmid = <STDIN>);

	print $pmid, "\n";

	my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=text&db=PubMed&uid=$pmid&dopt=abstract";  

	my $agent    = LWP::UserAgent->new;
	my $request  = HTTP::Request->new(GET => $url);
	my $response = $agent->request($request);
	$response->is_success or die "failed";

	my @ref = split(/\n\n/, $response->content);
		
#	unless ($ref[3] =~ /\)\:\d/) { splice(@ref, 3, 1) };

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




	print "TXCOPYRT\n";
	print $jtit, "\n";
	print $jdet, "\n";
#	print $journ, "\n";
	print $titl, "\n";
	print $auth, "\n";
	print "\n\n\n\n";

#print join("*\n\n", @ref), "\n";

}
print "NNNN\n";

}



