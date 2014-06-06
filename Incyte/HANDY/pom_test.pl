#!/software/arch/bin/perl -w

use strict;

use Pom::PomSim4;
use LWP::UserAgent;

my $sp = 'human';
my $chr = 'chr11';
my $contig = 'GBI_NT_009052_002.2';
my $est = '1222112H1';

# Create the WWW user agent.  Only needs to be done once per script
my $ua = new LWP::UserAgent;

# Variable for the returned object
my $pom;

# Derive the directory stub name from the contig name
my $stub = $contig;
$stub =~ s/_\d+(\.\d+)$/$1/;

# Construct the URL to fetch the entry.  Yuck.
my $url = 'http://krusty.incyte.com/cgi-bin/prioux/plaintext?PRETTY=OFF&' .
    "FLOW=$sp/$chr" . 
    '&LOC=STAGE&' .
    "FILE=$stub/Ests/$est\%3d$contig" . '.xml';

# Create an HTTP::Request object for the above URL...
my $request = HTTP::Request->new('GET' => $url);

# ... and pass it to the LWP::UserAgent.  This is the bit that
# actually contacts the remote WWW server.
my $response = $ua->request($request);

if ($response->is_success) {
    # If it worked, parse the returned XML into the Pom object
    $pom = Pom::PomSim4->StringToObject($response->content_ref, 'XML');

    # Print a few things from the Pom object
    print "PomSim4 uname: " . $pom->uname . "\n";
    print "PomSim4 coverage: " . $pom->coverage . "\n";

    print "EST sequence:\n";
    print $pom->est_fasta->sequence;
    print "\n";

    print "Exons:\n";

    foreach my $exon (@{$pom->exons}) {
	print "Coordinates: ";
	print join("\t", ( $exon->cdna_left,
			   $exon->cdna_right ));
	print "\n";
    }

    

    print "\n";
} else {
    # If it failed, print the HTTP error code.
    print $response->status_line;
}
