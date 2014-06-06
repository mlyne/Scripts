#!/usr/bin/perl -w

use Tk;
use Cwd;

$top = new MainWindow;
#print
    #"Filename: ",
    my $file = $top->getSaveFile(-defaultextension => ".txt",
		      -filetypes        =>
		      [['Text Files',       ['.txt', '.text']],		     
		       ['All Files',        '*',             ],
		      ],
		      
		      -initialdir       => Cwd::cwd(),
		      #-initialfile      => "getopenfile",
		      -title            => "Your customized title",
		     ),
#    "\n";

print $file, "***\n";

open(FH, "> $file") || die "cannot open file: $!";

print FH "blobby, Bob de Bob\n";

close FH;

__END__
