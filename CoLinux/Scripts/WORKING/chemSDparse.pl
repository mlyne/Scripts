#!/usr/bin/perl -w

# chemSDparse.pl

# pragmas
use strict;

# modules
use FileHandle;

# Usage
my $usage = "Usage: chemSDparse.pl [--help]

chemSDparse.pl <options> database(s)

\t--help   This list

Used for parsing entries from an SD database
databases

\n";

#unless ( $ARGV[0] ) { die $usage }

# mainline
STDOUT->autoflush (1);
STDERR->autoflush (1);
$/ = undef;

my $ifile;

foreach $ifile (@ARGV) 
{
  my $fh = new FileHandle $ifile, "r";
  if (defined $fh) 
  {
#    print "***reading $ifile***\n";
    while (<$fh>) 
    {
      my @entries = split(/\$\$\$\$\n/, $_);
      
      foreach my $entry (@entries)
      {
	      #next unless ($entry =~ /INN/ .. /\]/mg);
	      
		my @fields = split(/\> /, $entry);
	#	print join("***\n",@fields),"\n";
	    
		foreach my $field (@fields)
		{
	  		print $field if ($field =~ / END$/mg);
			print "> ", $field if ($field =~ /^\<PUBCHEM_SUBSTANCE_ID\>/mg);
			print "> ", $field if ($field =~ /^\<PUBCHEM_EXT_DATASOURCE_NAME\>/mg);
				  		
			if ($field =~ /^\<PUBCHEM_SUBSTANCE_SYNONYM\>/mg)
	  		{
				my @lines = split(/\n/, $field);
				print "\> ", $lines[0], "\n";
				my @names;
				foreach my $line (@lines)
				{
					if ( ( ($line =~ /INN/) || ($line =~ /:/) || ($line =~ /USA/)) && ($line =~ /\]/) )
					{
						#print $line, "\n" unless ( ($line =~ /anish/) || ($line =~ /atin/) || ($line =~ /ench/) );
						push (@names, $line);
					}
				}
							
				my $trueINN = grep /INN\]/, @names;
				my $colonINN = grep /\:/, @names;
				
				if ($trueINN)
				{
					my @generic;
					@generic = grep /INN\]/, @names;
					print join("; ", @generic), "\n";
				}
				
				elsif ($colonINN){
					my @generic;
					@generic = grep /:/, @names;
					print join("; ", @generic), "\n";
					
				}
				
				else {
					print join("; ", @names), "\n";
				}
				
				print "***No Name Defined***\n" unless @names;
				print "\n";
			}
			
			print "> ", $field if ($field =~ /CE_URL/mg);
		}
		print "\$\$\$\$\n";
		}
    }
  }
}

