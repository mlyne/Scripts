#!/usr/local/bin/perl -w
#

################################ CONFIG ####################################
use Getopt::Long;
use strict;

my $ARCH = "/home2/mlyne/TEMP/KRISTIAN/sunos5.6";
#my $DATADIR = "/home2/mlyne/TEMP/KRISTIAN/TEST";
my $DATADIR = "./";
my $PFPROBEDIR = "/home2/mlyne/PROBESET/PFAM/v_20010413";
my $TMHMMDIR = "/home2/mlyne/TEMP/KRISTIAN/TMHMM2.0/bin";
my $BLASTDIR = "\$BLASTDB";
my $CRUNCHDIR = "/biosoft/arch/bin/";
my $BLASTPARSEDIR = "/home2/mlyne/SCRIPTS/BLAST";

############################### PACKAGES ###################################
BEGIN {
  use IPC::Open2;                # For Controlling TMAP et al
  use IO::Handle;
}

my $usage = "Usage: HTP_TVDDscreen.pl [ options ] [--type=nt or --type=prot] file

Description:
High throughput filter for TVDD pipeline
Provides a wrapper for Rick Graul's probeset, Pfam drg Models
for TMAP, TMHMM, Incyte proprietary signal pep. prediction
models

Gives two types of output:
\tlong version with --long
\tshort version as default

Exmaple:
\tHTP_TVDDscreen.pl --long --type=prot file.aa

\n";



### command line options ###
my (%opts, $type, $long);

GetOptions(\%opts, 'help', 'type=s', 'long');
defined $opts{"help"} and die $usage;
defined $opts{"type"} and $type = $opts{"type"};
defined $opts{"long"} and $long++;

my $no_type = "You need to specify sequence type: DNA or Protein
\t--type=nt or --type=prot
\n";

($type) || die $no_type;

my ($nt, $prot);
($type =~ /nt/i || $type =~ /prot/i)|| die $no_type;
($type eq "nt") and $nt++;

###############################  GLOBALS  ##################################
my $QID = $$ . time; # The PID . time is a unique user ID
my $SEQ;     # The RAW FASTA Input Sequence(s)
my @SEQS;    # The individual FASTA Input Sequence(s)
my @SEQIDS;  # The Sequence IDs (>\S+)
my %RESULTS; # The RESULTS Data Structure
             # RESULTS{}{}[0] Raw Search Output 
             # RESULTS{}{}[1] Formatted Text Output
my %BRIEFRES;# Brief Output format for quick parsing
my @ORFS;    # FOR EST: The ORFS
my $ORFT=70; # FOR EST: The ORF Length threshold
my $PROCS=2; # The number of processors the job will run on 

################################ METHODS ###################################
my @METHODS = (
               'orfinfo',
               'iFamSigpept',
	       'PFdrgModels',
	       'TmHMM',
               'iFamTransmem',
               'tmap',
               'ProbeSet',
               'pFamLilly',
               'iFamNegative'
               );
my %METHODTITLES = (
                    'orfinfo' => "OPEN READING FRAMES &gt; $ORFT AA",
                    'iFamSigpept' => "HMMPFAM ~ SIGNAL PEPTIDE MODELS",
		    'PFdrgModels' => "HMMPFAM ~ DRUG MODELS",
		    'TmHMM' => "TmHMM2.0 ~ TRANSMEMBRANE PREDICTION",
                    'iFamTransmem' => "HMMPFAM ~ TRANSMEMBRANE MODELS",
                    'tmap' => "TMAP ~ TRANSMEMBRANE PREDICTION",
                    'ProbeSet' => "PROBESET ~ SECRETED PROTEIN BLAST HOMOLOGY",
                    'pFamLilly' => "HMMPFAM ~ LILLY PFAM MODELS",
                    'iFamNegative' => "BADFAM ~ THE STUFF YOU DON'T WANT"
                   );
############################## CONSTANTS ###################################
my $MAXREPORT = 2;

############################################################################
################################# MAIN #####################################
############################################################################
my ($inFile, $TEXTRES);
preprocessData();

if ($nt) {
  ESTPipeline();
}
else { proteinPipeline() };

$inFile = ($nt) ? "$DATADIR/file.orfs.$QID" : "$DATADIR/file.prot.$QID";

SIGpfam($inFile);
TMhmm($inFile);
Tmap($inFile);
BLASTprobeSet($inFile);
DRGpfam($inFile);
$TEXTRES = generateProteinText();
if ($long) {
  print "$TEXTRES";
} else { QuickOutput(); }
#archiveResults($TEXTRES);
clearUp($inFile);

########################## PREPROCESS DATA ################################
sub preprocessData {
  my $fileName;

  $fileName = $ARGV[0];
  local $/ = undef;
  open(INFILE, "< $fileName") or die "Can't open $fileName: $!\n";
  $SEQ = <INFILE>;

  @SEQS = split(/^>/m, $SEQ);
  shift @SEQS;
  foreach (@SEQS) { $_ = ">".$_ };

## Gather Info About IDS
  foreach (@SEQS) {
    if ( /^>(\S+)/ ) {
      push @SEQIDS, $1;
    }
    else {
      push @SEQIDS, "UNNAMED";
    }
  }
}

########################### The 
############################### Protein
#################################### Pipeline
sub proteinPipeline {

  ## SEQ CONTAINS MULTI FASTA
  ## SEQS CONTAINS INDIVIDUAL FASTAS

  open(PFAMFO, "> $DATADIR/file.prot.$QID");
  print PFAMFO $SEQ;
  close(PFAMFO);
}

################################### EST
####################################### Pipeline

sub ESTPipeline {

  ## SEQ CONTAINS MULTI FASTA
  ## SEQS CONTAINS INDIVIDUAL FASTAS

  my $rawOutput;
  my @rawOutput;
  my $Id;

  # Output EST's to file
  open(XFO, "> $DATADIR/file.est.$QID");
  print XFO $SEQ;
  close(XFO);

  ####################################  XLATE  #############################

  local $/ = undef;
  open(XLATE, "$ARCH/translation -f $DATADIR/file.est.$QID -p $ARCH/  -l $ORFT -o 1 |");
  $rawOutput = <XLATE>;
  close XLATE;

  $rawOutput =~ s/\cM//msg;
  @rawOutput = split(/^>/m, $rawOutput);
  shift @rawOutput;
  
  
  foreach (@rawOutput) {
    if (/^([^+\-]+)([+\-]\d)_ORF(\d).+?\[(\d+)\-(\d+)\]/) {
      my $Size = ($5 - $4) +1;
      $RESULTS{$1}{'orfinfo'}[0] .= "ORF $3 in frame $2\t$Size aa\tfrom $4 to $5\n";
      push @ORFS, ">$_";
    }
  }

  open(XFO, "> $DATADIR/file.orfs.$QID");
  foreach (@ORFS) {
    print XFO $_;
  }
  close(XFO);
}

#################################################################################
############# ANALYSIS ##### ANALYSIS ##### ANALYSIS ##### ANALYSIS #############
#################################################################################

#############################  BAYER SIGPEPT  ###################################
sub SIGpfam {

  my $in_file = shift;
  my $sigPFrawOutput;
  my $method = 'iFamSigpept';
  
  local $/ = undef;
  open(PFAM, "lsrun -R type==LINUX hmmpfam -A0 -T0 -E3000 $ARCH/pfam.bayer $in_file |");
  $sigPFrawOutput = <PFAM>;
  close PFAM;
  parsePFRawOutput($method, $sigPFrawOutput);
}

#############################  PFAM DRG MODELS  ################################
sub DRGpfam {
  
  my $in_file = shift;
  my $drgPFrawOutput;
  my $method = 'PFdrgModels';

  local $/ = undef;
  open(PFAM, "lsrun -R type==LINUX hmmpfam -A0 -T0 -E3000 $PFPROBEDIR/full-length.2001-04-13.hmm $in_file |"); 
  $drgPFrawOutput = <PFAM>;
  close PFAM;
  parsePFRawOutput($method, $drgPFrawOutput);
}

######################### TMHMM2.0 #########################
sub TMhmm {

  my $in_file = shift;
  my $TmHMMrawOutput;
  my $method = 'TmHMM';
  my @line = ();

#  local $/ = undef;
  open(TMHMM, "lsrun -R type==LINUX $TMHMMDIR/tmhmm -noplot  -short $in_file |");

  while (<TMHMM>) {
    @line = split("\t", $_);
    $line[3] =~ s/First60=//;
    $line[4] =~ s/PredHel=//;
    next unless (($line[3] >= 10) || ($line[4] >= 1));
    $TmHMMrawOutput .= $_;
  }
  close TMHMM;
  parseTmHMMRawOutput($method, $TmHMMrawOutput);
}
  
########################## TMAP ############################

sub Tmap {
  
  my $in_file = shift;
  local $/ = undef;

  if ($in_file =~ /orfs/) {
    foreach (@ORFS) {
      /^>([\.\S]+)[+\-]\d/;
      open2( *TMAPOUT, *TMAPIN, "$ARCH/tmapS" );
      print TMAPIN $_;
      close(TMAPIN);
      $RESULTS{$1}{'tmap'}[0] .= <TMAPOUT>;
      close(TMAPOUT);
    }
  }
  else {
    foreach (@SEQS) {
      /^>(\S+)\s/;
      open2( *TMAPOUT, *TMAPIN, "$ARCH/tmapS" );
      print TMAPIN $_;
      close(TMAPIN);
      $RESULTS{$1}{'tmap'}[0] = <TMAPOUT>;
      close(TMAPOUT);
    }
  }

  foreach my $Id ( @SEQIDS ) {
    if (defined $RESULTS{$Id}{'tmap'}[0]) {
      ##
      ## Create Plain Text output
      ##      
      generateTextTMAP($Id,'tmap');
    }
  }

}

######################## PROBE SET ###########################
sub BLASTprobeSet {

  my $in_file = shift;
  my $ProbeRawOutput;
  my $method = 'ProbeSet';

  local $/ = undef;
#  open(BLASTP, "lsrun -R type==LINUX blastall -p blastp -d probe.pep -i $in_file -e 0.1 -v 3 -b 3 |" .
#       "$CRUNCHDIR/MSPcrunch -d - | awk '{if ((\$1 >= 200) && (\$6 !~ /negative-secreted/)) print}' |" .
#       "sort -nr | perl $BLASTPARSEDIR/msp2hits2.pl -r 3 | perl $BLASTPARSEDIR/nr_list.pl -d |" );
  open(BLASTP, "lsrun -R type==LINUX blastall -p blastp -d probe.pep -i $in_file -e 0.1 -v 3 -b 3 |" .
       " $CRUNCHDIR/MSPcrunch -d - | sort -nr | perl $BLASTPARSEDIR/msp2hits2.pl -r 5 | sort +3 |" .
       " awk '{if ((\$1 >= 200) && (\$6 !~ /expand/)) print}' | perl $BLASTPARSEDIR/nr_list.pl -d |" .
       " $BLASTPARSEDIR/rmNegSecHits.pl |" );
  $ProbeRawOutput = <BLASTP>;
#  print "$ProbeRawOutput";
  close BLASTP;
  parseProbeRawOutput($method, $ProbeRawOutput);

}



############################################################
################### RAW OUTPUT PARSING #####################
############################################################

################## Parse PFAM Raw Output ###################
sub parsePFRawOutput {

  my $method;
  my $PFrawOutput;
  my @PFrawOutput;
  my $seqId;
  my $Id;

  ($method, $PFrawOutput) = @_;

  @PFrawOutput =  split(/^Query:\s+/m, $PFrawOutput);
  foreach (@PFrawOutput) { $_ = ">".$_ };
  shift @PFrawOutput;

  foreach ( @PFrawOutput ) { 
    if ( /^>([\.\S]+)[+\-]\d/ ) { # Used to be s//
      $seqId = $1;
    } 
    elsif ( /^>([\.\S]+)/ ) {
      $seqId = $1;
    }
    if (defined $RESULTS{$seqId}{$method}[0]) {
      $RESULTS{$seqId}{$method}[0] .= $_;
    }
    else {
      $RESULTS{$seqId}{$method}[0] = $_;
    }
  }

  foreach $Id ( @SEQIDS ) {
    if (defined $RESULTS{$Id}{$method}[0]) {
      ##
      ## Create Plain Text output
      ##      
      generateTextSigPept($Id, $method) if ($method =~ /iFamSigpept/);
      generateTextPfamDrg($Id, $method) if ($method =~ /PFdrgModels/);
    }
  }

}

######################## Pfam parse #####################
sub pfParse {

  my $pfResult;
  my $TopLine;
  my $ORFId;
  my $ORFNum;
  my $From;
  my $To;
  my $Frame;

  $pfResult = shift;

  if ( $pfResult =~ /^(\S+).+?\[(\d+)\-(\d+)\]/ ) {
    ($ORFId, $From, $To)  = ($1, $2, $3);
    $ORFId =~ /([+\-]\d)/;
    $Frame = $1;
    $ORFId =~ /ORF(\d+)/;
    $ORFNum = $1;
    $TopLine = "Nucleotide Translation: ORF $ORFNum in Frame $Frame from $From to $To";
  }
  elsif ( $pfResult =~ /^>([\.\S]+)\s/ ) {
    $TopLine = "Protein Sequence: $1";
  }
  else {
    $TopLine = "ERR1";
  }
  
  if ( $pfResult =~ m/no\shits/mi ) {
    $pfResult = "";
  }
  else {
    $pfResult =~ s/^.*?domains://msi;
    $pfResult =~ s/^.*?\sN\s//msi;
    $pfResult =~ s/^.*?E\-value\n//msi;
    $pfResult =~ s/^.*?\---\n//msi;
    $pfResult =~ s/\/\/$//msi;
    $pfResult =~ s/^\s*$//msg;
    $pfResult =~ s/^\n$//msg;
    $pfResult =~ s/^(\S+)\s+\S+\s+(\S+)\s+(\S+)\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)\s+(\S+)$/$1\t$2\t$3\t$4\t$5/msg;
  }
  return ($TopLine, $pfResult);
}

################## Parse TmHMM Raw Output ###################
sub parseTmHMMRawOutput {
  
  my $method;
  my $TmHMMrawOutput;
  my @TmHMMrawOutput;
  my $seqId;
  my $Id;

  ($method, $TmHMMrawOutput) = @_;


  if ($TmHMMrawOutput) {
    @TmHMMrawOutput =  split(/\n/m, $TmHMMrawOutput);

    foreach (@TmHMMrawOutput) { $_ = ">$_" };

    unless ($TmHMMrawOutput[0]) {shift(@TmHMMrawOutput) };

    foreach ( @TmHMMrawOutput ) { 
      if ( /^>([\.\S]+)[+\-]\d/ ) { # Used to be s//
	$seqId = $1;
      } 
      elsif ( /^>([\.\S]+)\t/ ) {
	$seqId = $1;
      }
      if (defined  $RESULTS{$seqId}{$method}[0]) {
	$RESULTS{$seqId}{$method}[0] .= $_;
      }
      else {
	$RESULTS{$seqId}{$method}[0] = $_;
      }
    }

    foreach $Id ( @SEQIDS ) {
      if (defined $RESULTS{$Id}{$method}[0]) {
	##
	## Create Plain Text output
	##      
	generateTextTmHMM($Id, $method);
      }
    }
  }
}

####################### Parse Probe Raw Output ########################
sub parseProbeRawOutput {
  
  my $method;
  my $ProbeRawOutput;
  my @ProbeRawOutput;
  my $seqId;
  my $Id;

  ($method, $ProbeRawOutput) = @_;

  if ($ProbeRawOutput) {
    @ProbeRawOutput =  split(/\n/m, $ProbeRawOutput);
    foreach (@ProbeRawOutput) { $_ = ">".$_ };
    unless ($ProbeRawOutput[0]) {shift(@ProbeRawOutput) };

    foreach ( @ProbeRawOutput ) { 
      if ( /^>\d+\t[\.\d]+\t\d+\t([\.\S]+)[+\-]\d_ORF/ ) { # Used to be s//
	$seqId = $1;
      } 
      elsif ( /^>\d+\t[\.\d]+\t\d+\t([\.\S]+)\t/ ) {
	$seqId = $1;
      }

      if (defined  $RESULTS{$seqId}{$method}[0]) {
	$RESULTS{$seqId}{$method}[0] .= $_;
      }
      else {
	$RESULTS{$seqId}{$method}[0] = $_;
      }
    }

    foreach $Id ( @SEQIDS ) {
      if (defined $RESULTS{$Id}{$method}[0]) {
	##
	## Create Plain Text output
	##      
#      print "$RESULTS{$Id}{$method}[0] pants\n";
	generateTextProbe($Id, $method);
      }
    }
  }
}
 
################################################
############### TEXT GENERATING ################
################################################

################# TEXT SIGPEPT PFAM ###################
sub generateTextSigPept { #OPT

  my $parsedRes;
  my @lines;
  my @fields;
  my $cleave;
  my $ident;

  $RESULTS{$_[0]}{$_[1]}[1] = "";

  my @Results = split( /\/\/\n/msi,  $RESULTS{$_[0]}{$_[1]}[0] );
  
  foreach (@Results) {
    ($ident, $parsedRes) = pfParse($_);
    if ($parsedRes) {
      @lines = split(/\n/, $parsedRes);
      @lines = sort byHMMScore @lines;
      @lines = splice @lines, 0, $MAXREPORT;
      ## Calculate Cleavage Site
      foreach (@lines) {
	@fields = split(/\s+/, $_);
	if ( $fields[0] =~ /^ISPB/ ) {
	  $cleave = $fields[2] - 2;
	}
	else {
	  $cleave = $fields[2];
	}
	$fields[4] = $cleave;
	$_ = join("\t", @fields);
      }        
      $parsedRes = join("\n", ("Model\tStart\tEnd\tScore\tCleaved", @lines));
    }
    if ($parsedRes) {
      $RESULTS{$_[0]}{$_[1]}[1] .= "$ident\n$parsedRes\n\n";
      push @{ $BRIEFRES{$_[0]} }, "SigP";
    }
  }

}


############################## TEXT TMHMM ##################################
sub generateTextTmHMM {

  my ($seqId, $frame, $orf);
  my @fields;
  my $Id;
  my $Topline;
  my $parsedRes;
  
  $RESULTS{$_[0]}{$_[1]}[1] = "";

  my @Results = split( />/msi, $RESULTS{$_[0]}{$_[1]}[0] );
  shift(@Results);

  foreach (@Results) {
    s/len=//msig;
    s/ExpAA=//msig;
    s/First60=//msig;
    s/PredHel=//msig; 
    s/Topology=//msig;
    @fields = split(/\t/, $_);
#    print $fields[0], "\n";
    $Id = shift( @fields );
    if ( $Id =~ /^\S+([+\-]\d)_ORF(\d)/ ) {
      $Topline = "Nucleotide Translation: ORF $2 in frame $1";
    }
    else {
      $Topline = "Protein Sequence: $Id";
    }
    $_ = join("\t", @fields);
    $parsedRes = join("\n", ("Len\tTmLen\tSigP\tTmCount\tTopology", $_));
    if ( $parsedRes ) {
      $RESULTS{$_[0]}{$_[1]}[1] .= "$Topline\n$parsedRes\n\n";
      push @{ $BRIEFRES{$_[0]} }, "TMHMM_$fields[3]";
    }
  }

}

################################# TEXT TMAP ################################
sub generateTextTMAP {
  
  my $TopLine;
  my $ORFId;
  my $ORFNum;
  my $Frame;

  $RESULTS{$_[0]}{$_[1]}[1] = "";

  my @Results = split( /^\[/msi,  $RESULTS{$_[0]}{$_[1]}[0] );
  
  foreach (@Results) {
    unless ( m/no\strans/mi ) {
      if ( /^([\.\S]+)([+\-]\d)_ORF(\d+)/ ) {
	$ORFId = $1;
	$Frame = $2;
	$ORFNum = $3;
	$TopLine = "Nucleotide Translation: ORF $ORFNum in Frame $Frame";
	s/^.*?PREDICTED\s+TOP/PREDICTED TOP/msi;
	s/^\s*$//msg;
	s/^\n$//msg;

	$RESULTS{$_[0]}{$_[1]}[1] .= "$TopLine\n$_\n";
	push @{ $BRIEFRES{$_[0]} }, "TMAP";
      }
    }
  }

}

################################ TEXT PROBE ###############################

sub generateTextProbe {

  my ($seqId, $frame, $orf);
  my @fields;
  my %resHash;
  my $Id;
  my @DrgCat;
  my $Topline;
  my $parsedRes;
  my %peptides = ();
  my $arVal;
  my @deRef =();
  
  $RESULTS{$_[0]}{$_[1]}[1] = "";

#  print "$RESULTS{$_[0]}{$_[1]}[0] pants\n";

  my @Results = split( />/msi, $RESULTS{$_[0]}{$_[1]}[0] );
  shift(@Results);

  foreach (@Results) {
    @fields = split(/\t/, $_);
    $Id = $fields[3];

    splice(@fields, 2, 1);
    splice(@fields, 3, 1);

    push @DrgCat, "$fields[3]";

    $_ = join("\t", @fields);

    push @{ $peptides{$Id} }, [ $_ ];
  }

  for my $arRef (keys %peptides) {
#    if ( $Id =~ /^\S+([+\-]\d)_ORF(\d)/ ) {
#      $Topline = "Nucleotide Translation: ORF $2 in frame $1";
#    }
#    else {
#      $Topline = "Protein Sequence: $Id";
#    }

    for ( @{ $peptides{$arRef} } ) {
#      print "$arRef => @$_ \n";
      push @deRef, @$_;
    }
      $parsedRes = join("\n", ("Score\t\%Id\tQuery\tDrgClass", @deRef) );
#      print "$parsedRes\n";
  }
      if ($parsedRes) {
#	$RESULTS{$_[0]}{$_[1]}[1] .= "$Topline\n$parsedRes\n\n";
	$RESULTS{$_[0]}{$_[1]}[1] .= "$parsedRes\n\n";
	push @{ $BRIEFRES{$_[0]} }, join("\/", @DrgCat);
      }
#  }

}

################# TEXT PFAM DRG MODELS###################
sub generateTextPfamDrg { #OPT

  my $Result;
  my $parsedRes;
  my @lines;
  my @fields;
  my $ident;

  $RESULTS{$_[0]}{$_[1]}[1] = "";

  my @Results = split( /\/\/\n/msi,  $RESULTS{$_[0]}{$_[1]}[0] );
  
  foreach $Result (@Results) {
    ($ident, $parsedRes) = pfParse($Result);
    if ($parsedRes) {
      @lines = split(/\n/, $parsedRes);
      @lines = sort byHMMScore @lines;
      foreach (@lines) {
	@fields = split(/\s+/, $_);
	$_ = join("\t", @fields);
      }
      $parsedRes = join("\n", ("Model\tStart\tEnd\tScore\tE-value", @lines));
    }
    if ( $parsedRes ) {
      $RESULTS{$_[0]}{$_[1]}[1] .= "$ident\n$parsedRes\n\n";
    }
  }
}


############################################################################
######################## TEXT SUMMARY GENERATION ###########################
############################################################################
sub generateProteinText {
  
  my $Output = "";
  my $Id;
  my $Method;
  
  foreach $Id ( @SEQIDS ) {
##
##Sequence ID
##
    $Output .= <<END_TEXT;

------------------------------------------
SEQUENCE: $Id
------------------------------------------
END_TEXT

##
## METHOD
##
    foreach $Method (@METHODS) {
      if (defined $RESULTS{$Id}{$Method}[0]) {
        $Output .= ">$METHODTITLES{$Method}";
      }
##
## METHOD DATA
##  
      if (defined $RESULTS{$Id}{$Method}[1]) {
        $Output .= "\n" . $RESULTS{$Id}{$Method}[1]. "\n";
      }
      elsif (defined $RESULTS{$Id}{$Method}[0]) {
        $Output .= "\n" . $RESULTS{$Id}{$Method}[0] . "\n";
      }
    }
    
  }
  return $Output;
  
}

################### Test QOut ################
sub QuickOutput {

  my @uniq = ();

  for my $key (keys %BRIEFRES) {
    my %h = map { $_, 1 } @{ $BRIEFRES{$key} };
    @uniq =  sort keys %h;
    print "$key\t", join("\t",  @uniq), "\n";
  }

}

##################################################################################
sub byHMMScore
{
    return ( split(/\s+/, $b) )[3] <=> ( split(/\s+/, $a) )[3];
}

sub archiveResults {
  open AFO, "> ./archive/$QID";
  print AFO "$_[0]";
  close AFO;
}

sub clearUp {
  
  my $in_file = shift;

  if ($in_file =~ /orfs/) {
    unlink("$DATADIR/file.est.$QID");
    unlink("$DATADIR/file.orfs.$QID");
  }
  else {
    unlink("$DATADIR/file.prot.$QID");
  }

}
