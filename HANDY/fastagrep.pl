#!/usr/bin/perl 

# fastagrep.pl
 
# modified to provide reverse complementation of the pattern - not publicly    released yet

use strict;
use Getopt::Std;
use IO::File;

#globals  
my $pattern;
my $hits;
my $count;
my $line;
my $text;
my $preserved;
my $preservedText;
my $searchBoth; # flag indicating look in both DNA and text
my $dna;
my $searchOptions='';
my @patArray;
my %opt;

$ARGV[0] || &help_text;

&Getopt::Std::getopts('chivtDp:PRf:', \%opt) || &help_text("invalid option") ;
# D look for a match only in the sequence
# t look for a match only in the text info line
# i search case insensitive
# c count matching records
# v output the non matching records
# p the pattern to search for
# f get the patterns from a file, one pattern per line
# P preserve the line structure of the sequence
# h give help
# R reverse complement the pattern before searching (not a public option yet)
# need to check that pattern is DNA. probably ought to revcomp IUPACs too.

if (exists $opt{'h'}){ &help_text;}
if ( (!(exists $opt{'p'})) && (!(exists $opt{'f'} ))) { 
  &help_text ("no pattern to match\n");
}

if ($opt{f}){ # get the list of patterns into an array
  my $FH = new IO::File "$opt{f}";
  my $c=0;
  if (defined $FH){
    while(<$FH>){
      chop;
      if ($_){
        $patArray[$c]=$_;
        $c++;
      }
    }
  }else{
  die "couldn't access file $opt{f}";
  }
}else{ # construct search pattern
  if(exists $opt{'i'}){ 
    $searchOptions='(?i)';
  }
  $pattern=$searchOptions.$opt{'p'};
}

if ( $opt{'R'} == 1){ # reverse complement the pattern
  $opt{'p'} = reverse( $opt{'p'} );
  $opt{'p'} =~ tr/agct/tcga/;
  $opt{'p'} =~ tr/AGCT/TCGA/; 
}

# if D or t are not given look in both DNA and text
# to do this economically we can concatenate them
if ( (! exists $opt{'t'}) && (! exists $opt{'D'}) ){
  $opt{'t'}=1;
  $opt{'D'}=1;
  $searchBoth=1;
}

# if both D and t are given we need to search both
# so concatenate them
if ( ( exists $opt{'t'}) && ( exists $opt{'D'}) ){
  $searchBoth=1;
}

=head1
# construct search pattern
if(exists $opt{'i'}){ 
  $searchOptions='(?i)';
}
$pattern=$searchOptions.$opt{'p'};

=cut

# here we go 2,3,4.
while ( ($text = <>) !~ />/){ # read in comments and blank lines
#do nothing until we get a >
}
# $text contains first info line
$hits =0; # number of matching records or if -v non matching records
$count=0;
while ($text){

  $dna=&get_next_sequence || die (" record with info = $text\n has no dna\n") ;
  $count++;
  
  # some fasta files have spaces in the DNA so strip them out
  # this only matters if we are searching the DNA 
  # (and when we are printing out)  
  if (exists $opt{'D'}){
    $dna =~ tr/ //d;
  }

  # if we are searching both concat dna onto $text
  if ($searchBoth){
    if ($opt{'P'}){ # but first preserve the text
      $preservedText=$text;
    }
    $text.=$dna;
  }

  # look for sequences that match
    if (exists $opt{'t'}){ #ie searching just text or both
      #if ($text =~ /$pattern/){
      if (&got_a_match($text)){
        # we got a match
	if(! exists $opt{'v'}){ # if we want matching 
	  $hits++;
	  if(! exists $opt{'c'}){ # if we aren't just counting
            &output_record;
	  }
        }
      }else{ # we didn't get a match
        # if we want not matching
	if( exists $opt{'v'}){ 
	  $hits++;
	  if(! exists $opt{'c'}){ # if we aren't just counting          
            &output_record;
	  }
        }
      }
    }else{ # not searching text      
      # we are looking in the dna only
      #if ($dna =~ /$pattern/){
      if (&got_a_match($dna)){
        # we got a match
	if(! exists $opt{'v'}){ # if we want matching 
	  $hits++;
	  if(! exists $opt{'c'}){ # if we aren't just counting
            &output_record;
	  }
        }
      }else{ # we didn't get a match
        # if we want not matching
	if( exists $opt{'v'}){ 
	  $hits++;
	  if(! exists $opt{'c'}){ # if we aren't just counting          
            &output_record;
	  }
        }
      }     
    }

  $text=$line;
}

if( exists $opt{'c'}){ 
  print $hits."\n";
}


exit(0);

#########################################################################


sub got_a_match{
  my $text=shift;

  my $pat;

  if (!$opt{f}){ # if we're not searching a list
    if ($text =~ /$pattern/){
      return (1);
    }else{
      return(0);
    }
  }

  # see if any of the items in the patArray match in the text
  foreach $pat (@patArray){
    if ($text =~ /$pat/){
      return (1);
    }
  }
  return(0);
}


sub output_record{

  if ($searchBoth){ #text and all dna lines have been munged together
    if ($opt{'P'}){
      print $preservedText;
      print $preserved;
    }else{
    print $text."\n\n";
    }
  }else{
    print  $text;
    if ($opt{'P'}){
      print $preserved;
    }else{
      #remove spaces in DNA
      $dna =~ tr/ //d;
      print $dna."\n\n";
    }
  }
}


sub get_next_sequence{

  my $dna;
  $preserved='';
 
  # there may be more than one line of dna
  while ( ($line = <>) && ($line !~ />/)){ # read in dna (or maybe blank line)
    $preserved .= $line;
    chop ($line); # get rid of newline or blank line
    $dna .= $line;
  }
  # $line now contains the info line for the next sequence but
  # if we got to the end of the file it doesn't
  if($dna) {return($dna);}
  return(0);
  
} 


sub help_text{
  my $errmsg=shift;

  if ($errmsg){  print "\n$errmsg\n";}

print << "END_OF_HELP";

 fastagrep.pl -[options] -p pattern [file]

 D look for a match only in the DNA sequence
 t look for a match only in the text info line
 i make search case insensitive
 c count matching records, or if -v is used, non-matching records
 v output the non-matching records instead of those that match
 p the pattern to search for [mandatory]
 P preserve the line structure of the file. Useful for dbSNPs
 h gets these helpful hints
 f get the patterns from a file, one pattern per line. regexps not supported.

 NB. This program works much faster if you use the -D or -t options.

     Ordinary grep is best if you just want the info lines.

     If you want just the DNA lines, pipe the output from 
     fastagrep.pl into  grep -v '>'

 Version 2 April 2001 by PDK

END_OF_HELP

  exit(0);
}
