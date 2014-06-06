#!/usr/bin/perl -w

# refSummaryParse.pl

# pragmas
use strict;

# standard
use FileHandle;
use Getopt::Long;

# modules

my $usage = "Usage: GenBank_parse.pl [--help]

refSummaryParse.pl <options> database(s)

\t--help   This list

Used for parsing Summary template information from
LocusLink databases

Options:
\t--locus          Locus ID
\t--org            Organism
\t--mrna           mRNA ID
\t--prot           Protein ID
\t--symb           Gene Symbol
\t--name           Gene Name
\t--alias          Alternative Symbols
\t--psym           Preferred Symbol (when Gene Symbol absent)
\t--prod           Preferred Product Name
\t--sum            Summary Description of Protein Function
\t--alpro          Alternative Protein Names
\t--omim           Omim ID
\t--phe            Disease Phenotype info.

\t--all            All above (where available)

\n";

#unless ( $ARGV[0] ) { die $usage }

### command line options ###
my (%opts, $comlocus, $comorg, $commrna, $comprot, $comsymb, $comname, $comalias, $compsym, $comprod, $comsum, $comalpro, $comomim, $comphe);

GetOptions(\%opts, 'help', 'all', 'locus', 'org', 'mrna', 'prot', 'symb', 'name', 'alias', 'psym', 'prod', 'sum', 'alpro', 'omim', 'phe');
defined $opts{"help"} and die $usage;

defined $opts{"locus"} and $comlocus++;
defined $opts{"org"} and $comorg++;
defined $opts{"mrna"} and $commrna++;
defined $opts{"prot"} and $comprot++;
defined $opts{"symb"} and $comsymb++;
defined $opts{"name"} and $comname++;
defined $opts{"alias"} and $comalias++;
defined $opts{"psym"} and $compsym++;
defined $opts{"prod"} and $comprod++;
defined $opts{"sum"} and $comsum++;
defined $opts{"alpro"} and $comalpro++;
defined $opts{"omim"} and $comomim++;
defined $opts{"phe"} and $comphe++;

defined $opts{"all"} and ($comlocus++, $commrna++, $comprot++, $comsymb++, $comname++, $comalias++, $compsym++, $comprod++, $comsum++, $comalpro++, $comomim++, $comphe++);


# globals
my ($pfacc, $pfid, $pfcnt);
my (@new_entry, @locus, @org, @mrna, @prot, @symb, @name, @alias, @psym, @prod, @sum, @alpro, @omim, @phe);

# mainline

STDOUT->autoflush (1);
STDERR->autoflush (1);
$/ = ">>";

my $ifile;

foreach $ifile (@ARGV) 
{
  my $fh = new FileHandle $ifile, "r";
  if (defined $fh) 
  {
    while (<$fh>) 
    {
      chomp;

	if (/Homo sapiens/)
	{
		my @lines = split(/\n/, $_);
	    
	    
	foreach my $line (@lines)
	{
	  chomp;
#	  print "$line\n";
	  	if ($line =~ /^LOCUSID:\s+(\d+)/)
	  {		
	    my $locus = $1;
	    push(@locus, $locus) if $comlocus;
	  }

	  if ($line =~ /^ORGANISM:\s+(Homo sapiens)/)
	  {
	    my $org = $1;
	    push(@org, $org) if $comorg;
	  }
	      
	  if ($line =~ /^NM:\s+(NM_\d+)\|/)
	  {
	    my $mrna = $1;
	    push(@mrna, $mrna) if $commrna;
	  }
	    
	  if ($line =~ /^NP:\s+(NP_\d+)\|/)
	  {
	    my $prot = $1;
	    push(@prot, $prot) if $comprot;
	  }
	    
	  if ($line =~ /^OFFICIAL_SYMBOL:\s+(.+)$/)
	  {
	    my $symb = $1;
	    push(@symb, $symb) if $comsymb;
	  }
	  
	  if ($line =~ /^OFFICIAL.GENE.NAME:\s+(.+)$/)
	  {
	    my $name = $1;
	    push(@name, $name) if $comname;
	  }
	  
	  if ($line =~ /^ALIAS_SYMBOL:\s(.+)$/)
	  {
	    my $alias = $1;
	    push(@alias, $alias) if $comalias;
	  }
	  	  
	  if ($line =~ /^PREFERRED_SYMBOL:\s(.+)$/)
	  {
	    my $psym = $1;
	    push(@psym, $psym) if $compsym;
	  }
	  
	  if ($line =~ /^PREFERRED_PRODUCT:\s(.+)$/)
	  {
	    my $prod = $1;
	    push(@prod, $prod) if $comprod;
	  }
	  
	  if ($line =~ /^SUMMARY: Summary:\s(.+)$/)
	  {
	    my $sum = $1;
	    push(@sum, $sum) if $comsum;
	  }
	  
	  if ($line =~ /^ALIAS_PROT:\s(.+)$/)
	  {
	    my $alpro = $1;
	    push(@alpro, $alpro) if $comalpro;
	  }
	  
	  if ($line =~ /^OMIM:\s(.+)$/)
	  {
	    my $omim = $1;
	    push(@omim, $omim) if $comomim;
	  }	  	
	  	  
	  if ($line =~ /^PHENOTYPE:\s(.+)$/)
	  {
	    my $phe = $1;
	    push(@phe, $phe) if $comphe;
	  }	  	
	  
	}

	print "> LOCUS: ", @locus, "\n" if @locus;
	print "ORGANISM: ", join(',', @org), "\n" if @org;
	print "mRNA_ID: ", join(',', @mrna), "\n" if @mrna;
	print "PROT_ID: ", join(',', @prot), "\n" if @prot;
	print "SYMBOL: ", @symb, "\n" if @symb;
	print "GENE_NAME: ", @name, "\n" if @name;
	print "ALIAS: ", join(',', @alias), "\n" if @alias;
	print "PREF_SYMB: ", @psym, "\n" if @psym;
	print "PRODUCT: ", @prod, "\n" if @prod;
	print "SUMMARY: ", @sum, "\n" if @sum;
	print "PROD_ALIAS: ", join(',', @alpro), "\n" if @alpro;
	print "OMIM_ID: ", join(',',@omim), "\n" if @omim;
	print "PHENOTYPE: ", join(',', @phe), "\n" if @phe;
	print "=\n";
	  
	(@locus, @org, @mrna, @prot, @symb, @name, @alias, @psym, @prod, @sum, @alpro, @omim, @phe) = ();
	
      }
    }
  }
}

