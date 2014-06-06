#!/usr/bin/perl
use XML::Parser;
my $parser = new XML::Parser ();

# Now we can set the handlers:

$parser->setHandlers (
          Start => \&Start_handler,
            End => \&End_handler,
        Default => \&Default_handler
);

# Now we're going to read a filename from the command line:

my $filename = shift;
die "Can't find '$filename': $!\n" unless -f $filename;

# And here is the line that will make everything work
# (BTW, make sure that you read the XML::Parser documentation,
# because there are many other ways of calling it!):

$parser->parsefile ($filename);

# But wait!!! We can't forget to include the subs that will
# actually handle the events. We have defined their names

### HANDLERS ###

sub Start_handler {
  my $p  = shift;
  my $el = shift;

  print "<$el>\n";
  while (my $key = shift) {
    my $val = shift;
    print "  $key = $val\n";
  }
  print "\n";
}

###

sub End_handler {
  my ($p,$el) = @_;
  print "</$el>\n";
}

###

sub Default_handler {
  my ($p,$str) = @_;
  print "  default handler found '$str'\n";
}

