#!/usr/bin/perl

use strict;
use warnings;
use Net::FTP;

use feature ':5.12';

my $hostname = 'ftp.ncbi.nlm.nih.gov';
my $username = 'anonymous';
my $password = 'mike@intermine.org';

# Hardcode the directory and filename to get
my $home = '/genomes/Bacteria';

# Open the connection to the host
my $ftp = Net::FTP->new($hostname);        # Construct object
$ftp->login($username, $password);      # Log in

$ftp->cwd($home);                  # Change directory
say $ftp->nlst(), "\n"; 
#say $ftp->list(), "\n";        

$ftp->quit;

exit(1);
