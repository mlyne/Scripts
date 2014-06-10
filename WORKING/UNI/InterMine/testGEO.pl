#!/usr/bin/perl -w

use strict;
use warnings;
#use LWP;

#my $id_file = $ARGV[0];
my $array_file = $ARGV[0];

#my $out_file = $ARGV[1];

# open(ID_FILE, "< $id_file") || die "cannot open $id_file: $!\n";
# 
# my %ids;
# while (<ID_FILE>) {
#   chomp;
#   my $idLine = $_;
#   my ($id, $gene) = split("\t", $idLine, 2);
#   $ids{$id} = $gene;
# }
# 
# close (ID_FILE);
# 
# foreach my $key ( sort { $a <=> $b } keys %ids )
# {
# #  print "key: " . $key . " value: " . $ids{$key} . "\n";
# }

open(EXP_FILE, "< $array_file") || die "cannot open $array_file: $!\n";
#open(OUT_FILE, "> $out_file.txt") || die "cannot open $out_file: $!\n";

my ($data_h, $title, $geoAcc, $pmid, $summary, $protocol, $expDesc, $geoIDs);
my (@expHead, @conditions, @matrix);
while (<EXP_FILE>) {
  chomp;
  my $line = $_;

# Series_title
  if ($line =~ /Series_title/) {
    $line =~ s/\!Series_title\t//;
    $line =~ s/\"//g;
    $title = $line;
    next;
  }

# Series_geo_accession
  if ($line =~ /Series_geo_accession/) {
    $line =~ s/\!Series_geo_accession\t//;
    $line =~ s/\"//g;
    $geoAcc = $line;
    next;
  }

# Series_pubmed_id
  if ($line =~ /Series_pubmed_id/) {
    $line =~ s/\!Series_pubmed_id\t//;
    $line =~ s/\"//g;
    $pmid = $line;
    next;
  }

# Series_summary
  if ($line =~ /Series_summary/) {
    $line =~ s/\!Series_summary\t//;
    $line =~ s/\"//g;
    $summary = $line;
    next;
  }
# Series_overall_design
  if ($line =~ /Series_overall_design/) {
    $line =~ s/\!Series_overall_design\t//;
    $line =~ s/\"//g;
    $summary .= " ";
    $summary .= $line;
    next;
  }
#
# Sample_label_protocol_ch1
  if ($line =~ /Sample_label_protocol_ch1/) {
    $line =~ s/\!Sample_label_protocol_ch1\t//;
    $line =~ s/\"//g;
    $line =~ s/\t.+//;
    $protocol .= $line;
    next;
  }

# Series_platform_id
# Sample_hyb_protocol
#   if ($line =~ /Sample_hyb_protocol/) {
#     $line =~ s/\!Sample_hyb_protocol\t//;
#     $line =~ s/See www\.nimblegen\.com\.//;
#     $line =~ s/\"//g;
#     $line =~ s/\t.+//;
#     $protocol .= "\n";
#     $protocol .= $line;
#     next;
#   }

# Sample_scan_protocol
  if ($line =~ /Sample_scan_protocol/) {
    $line =~ s/\!Sample_scan_protocol\t//;
    $line =~ s/\"//g;
    $line =~ s/\t.+//;
    $line =~ s/^/Hybridization and /;
    $line =~ s/was/were/;
    $protocol .= " ";
    $protocol .= $line;
    next;
  }

# Sample_data_processing - three lines
  if ($line =~ /Sample_data_processing/) {
    $line =~ s/\!Sample_data_processing\t//;
    $line =~ s/\"//g;
    $line =~ s/\t.+//;
    $protocol .= " ";
    $protocol .= $line;
    next;
  }

# sample_title
  if ($line =~ /Sample_title/) {
    $line =~ s/\"//g;
    $data_h = $line;
    next;
  }

# Sample_description
  if ($line =~ /Sample_description/) {
    $line =~ s/\"//g;
    $expDesc = $line;
    next;
  }

  if ($line =~ /ID_REF/) {
    $geoIDs = $line;
    next;
  }

# removed for testing
#  if ( ($geoIDs) && ( $line !~ /series_matrix_table_end/) ) {
#    push(@matrix, $line);
#  }
  
    if ( $line !~ /series_matrix_table_end/ ) {
    push(@matrix, $line);
  }
}

close (EXP_FILE);

# print "//TITLE\t$title\n",
#   "//GEO_ACC\t$geoAcc\n",
#   "//PMID\t$pmid\n",
# 
#   "//SUMMARY\t$summary\n",
#   "//PROTOCOL\t$protocol\n";

# split expression data into new array
@expHead = split("\t", $data_h);
shift (@expHead);

@conditions = split("\t", $expDesc);
shift (@conditions);

# how many columns
my $elCnt = $#expHead;

# going to be used to track data co-ordinates
my @expPos;

# going to be used to track seen items
my (%seen);

my $posn = 0;

foreach my $head (@expHead) {
  my ($exp, $rep) = split("_", $head); # exper, replicate#

  if ($exp =~ m"/t") {
    $posn++; # increment array posn
    next; # get rid of technical replicates
  }
  
  push ( @{ $seen{$exp} }, $posn );
#  print "$exp, $rep, $posn\n";
  $posn++; # incr. array posn
}

my %col_order;
foreach my $key (keys %seen) {
  $col_order{$key} = $seen{$key}[-1];
#  print "CHECK: ", $key, "\t", join('; ', @{ $seen{$key} } ), "\n";
}


# remove replicate info from descn
map { s/_replicate \d//d; $_ } @conditions;
map { s/_technical replicate of replicate \d//d; $_ } @conditions;

print "//CONDITIONS"; # print exp conditions leader

for my $key ( sort { $col_order{$a} <=> $col_order{$b} } keys %col_order ) {
  my $posn = $col_order{$key};
#  print "POSN_CHECK: ", $key, "\t", $conditions[$posn], "\t", join('; ', @{ $seen{$key} } ), "\n"; ## for testing
  print "\t", $conditions[$posn];
}

print "\n";

print "//EXPER"; # print leader for headers

# exp headers preserving order
for my $key ( sort { $col_order{$a} <=> $col_order{$b} } keys %col_order ) {
  print "\t", $key;
}

print "\n";

## print "N: ", scalar(@matrix), "\n"; # for testing

for my $entry (@matrix)
{
  my @exprVal = split("\t", $entry);
  my $name = shift(@exprVal);
#  print $name, "\t", $ids{$name} if ( exists $ids{$name} ) || die "NO IDENTIFIER: $entry\n";

##  print $name, "\t";

  my (@newData, @CVs, @rowVals, @pVals);
  for my $key ( sort { $col_order{$a} <=> $col_order{$b} } keys %col_order ) {
#    print "SLICE:", $key, "\t", join('; ', @{ $seen{$key} } ), "\n";
    
    my ($currVal, @slice);
    for my $val (@{ $seen{$key} } ) {
      $currVal = $exprVal[$val];
      push(@slice, $currVal);
      push(@rowVals, $currVal);
    }

#     my ($mean, $sd, $cv, $reps) = &computeStats( \@slice );
#     $mean = ($mean) ? $mean : $currVal;
#     $cv = "" if ($reps < 2);
#     push (@newData, $mean);
#     push (@CVs, $cv);

#    print "\t$mean, $sd, $cv, $reps\n";

### Ignore - not used ###
### ANOVA
#     my $d2 = "globalMean";
#     my $pval = &anova ($key, $d2, \@slice, \@rowVals);
#     push(@pVals, $pval);

  }
#  my $roundPvals = &stround(3, \@pVals);

#   my ($row_mean, $row_sd, $row_cv, $row_reps) = &computeStats( \@rowVals );
# 
#   my @diffExpr = map { $_ - $row_mean } @newData;
#   my $roundExpr = &stround(3, \@diffExpr);
#   my $roundCV = &stround(3, \@CVs);
# #  print "\t$row_mean, $row_sd, $row_cv, $row_reps\n";
# 
#   for (my $i = 0; $i < @diffExpr; $i++) {
# #    print  "\t", @{ $roundExpr }[$i], " :", @{ $roundPvals }[$i];
#     print  "\t", $newData[$i], "|", @{ $roundExpr }[$i], "|", @{ $roundCV }[$i];
#   }
# 
# #  print "\t", join("\t", @{ $roundExpr } ), "\t", "*** $row_mean ***", "\n";
# #  print "\t", join("\t", @pVals), "\tnoVal\n";
#   print "\n";
}

### subroutines ###
sub computeStats {

  my ($data) = @_;
  my $mean = new Statistics::Basic::Mean($data)->query;
  my $sd = ($mean) ? new Statistics::Basic::StdDev($data)->query : "NA";
  my $cv = ($mean) ? (($sd / $mean) * 100) : "NA";
#  print "\t$mean, $sd, $cv, ", scalar(@$data), "\n";
  return ( $mean, $sd, $cv, scalar(@$data) );
}

sub anova {
  my ($dataID1, $dataID2, $dataRef1, $dataRef2) = @_;

  my $aov = Statistics::ANOVA->new();

  $aov->load( "$dataID1", @{ $dataRef1 } );
  $aov->add( "$dataID2", @{ $dataRef2 } );
#     $aov->add( "$dataID2", \@{$datasets{$dataset}[1]} );

  my $str = $aov->anova(independent => 1, parametric => 1, ordinal => 0);
#  $aov->anova(independent => 1, parametric => 1)->dump(title => 'Indep. groups parametric ANOVA', eta_squared => 1, omega_squared => 1);
#  $aov->compare(independent => 1, parametric => 1, flag => 1, alpha => .05, dump => 1); # Indep. obs. F- (or t-)tests
  my $pval = $str->{_stat}->{p_value};
}

sub stround {
    my( $places, $arrRef ) = @_;

    my @arrRound;
    foreach my $n ( @{ $arrRef } ) {
      if ($n =~ /\d/) {
	my $sign = ($n < 0) ? '-' : '';
	my $abs = abs $n;
	my $val = $sign . substr( $abs + ( '0.' . '0' x $places . '5' ), 0, $places + length(int($abs)) + 1 );
	push(@arrRound, $val);
      } else {
	my $val = $n;
	push(@arrRound, $val);
      }
    }
    return (\@arrRound);
}