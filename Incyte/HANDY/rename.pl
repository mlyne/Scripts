#!/usr/local/bin/perl -w
#
# rename - Larry's filename fixer
#
$usage = "Usage: rename expr [files]
See script head for examples\n";
#e.g.
#% rename 's/\.orig\$//'  *.orig
#% rename 'tr/A-Z/a-z/ unless /^Make/'  *
#% rename '$_ .= ".bad"'  *.f
#% rename 'print "$_: \"; s/foo/bar/ if <STDIN> =~ /^y/i'  *
#% find /tmp -name '*~' -print | rename 's/^(.+)~$/.#$1/'

$op = shift or die $usage;

chomp(@ARGV = <STDIN>) unless @ARGV;
for (@ARGV) 
{
  $was = $_;
  eval $op;
  die $@ if $@;
  rename($was,$_) unless $was eq $_;
}
