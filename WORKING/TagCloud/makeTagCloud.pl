#!/usr/bin/perl

use strict;
use warnings;

# load in tag file
my $tagfile = shift;
$tagfile = 'genesis.pl' if !$tagfile;

require "$tagfile";
die ("No tags loaded\n") if (!$mytags::tags);
my $tags = $mytags::tags;

my $useLogCurve = 1;
my $minFontSize = 10;
my $maxFontSize = 36;
my $maxtags = 200;

my $fontRange = $maxFontSize - $minFontSize;

my @sortkeys = sort {$tags->{$b}->{count} <=> $tags->{$a}->{count}} keys %{$mytags::tags};
@sortkeys = splice @sortkeys, 0, $maxtags;

# determine counts
my $maxTagCnt = 0;
my $minTagCnt = 10000000;

foreach my $k (@sortkeys)
{
  $maxTagCnt = $tags->{$k}->{count} if $tags->{$k}->{count} > $maxTagCnt;
  $minTagCnt = $tags->{$k}->{count} if $tags->{$k}->{count} < $minTagCnt;
}

my $minLog = log($minTagCnt);
my $maxLog = log($maxTagCnt);
my $logRange = $maxLog - $minLog;
$logRange = 1 if ($maxLog == $minLog);

sub DetermineFontSize($)
{
  my ($tagCnt) = @_;
  my $cntRatio;

  if ($useLogCurve) {
    $cntRatio = (log($tagCnt)-$minLog)/$logRange;
  }
  else {
    $cntRatio = ($tagCnt-$minTagCnt)/($maxTagCnt-$minTagCnt);
  }
  my $fsize = $minFontSize + $fontRange * $cntRatio;
  return $fsize;
}

# output beginning of tag cloud
print <<EOT;
<html>
<head>
  <link href="mystyle.css" rel="stylesheet" type="text/css">
</head>
<body>
<div class="cdiv">
<p class="cbox">
EOT

# output individual tags
foreach my $k (sort @sortkeys)
{
  my $fsize = DetermineFontSize($tags->{$k}->{count});
  my $url = $tags->{$k}->{url};
  my $tag = $tags->{$k}->{tag};
  printf "<a href=\"%s\" style=\"font-size:%dpx;\">%s</a>\n", 
    $url, int($fsize), $tag;
}

# output end of tag file
print <<EOT;
</p>
</div>
</body></html>
EOT


