=head1 NAME

AnT::Feature - Object representing a generic feature on a biological
sequence

=head1 SYNOPSIS

use strict;
use AnT::Seq;
use AnT::Feature;

my $seq = AnT::Seq->new
    (
     -id   => 'my_seq',
     -desc => 'a made-up sequence',
     -str  => 'tatcttatttctagtcgtttggggatatcgatcacatgcgacgtta',
     -type => 'dna'
    );

# Specifying -start and -end implicitly creates an AnT::Range
# object over this region. An alternative option is to create
# one (or more for spliced features) and add them to the
# feature using the -ranges argument to the constructor

my $feature = AnT::Feature->new
    (
     -key    => 'misc_feature',
     -start  => 5,
     -end    => 20,
     -strand => 1
    );

$feature->qadd('note', "Note number one", "Note number two");
$feature->qadd('label', "A label");

# Attach feature to sequence
$seq->features($feature);

# Access sequence and qualifiers
print "Feature has sequence ", $feature->str, "\n";

my @notes = $feature->note;
print join("\n", @notes), "\n";

=head1 DESCRIPTION

An AnT::Feature object represents a generic sequence feature which
may be attached to an AnT::Seq object. A feature contains AnT::Range
objects which define the regions of the sequence to which this
annotation refers. To attach a feature to an AnT::Seq object it must
contain at least one AnT::Range object.

AnT::Range objects are added or removed from a feature using methods
provided by the AnT::Feature object.

The AnT::Feature object makes available various methods to access its
position, strand, key and qualifiers. As the feature contains a
reference to the AnT::Seq object it is attached to, methods for
getting its sequence string and sequence type are also available.

An extra method corresponding to each qualifier is AUTOLOADED on
request i.e. $feature->note will return a list of notes (if any
are present) or undef otherwise. These methods are dynamic and
one will always be created for each qualifier name.

=head1 METHODS

See below. Methods private to this module are prefixed by an
underscore.

=head1 AUTHOR

Keith James (kdj@sanger.ac.uk)

=head1 ACKNOWLEDGEMENTS

See AnT.pod

=head1 COPYRIGHT

Copyright (C) 2000 Keith James. All Rights Reserved.

=head1 DISCLAIMER

This module is provided "as is" without warranty of any kind. It may
be used, redistributed and/or modified under the same conditions as
Perl itself.

=cut

package AnT::Feature;

use strict;
use Carp;
use AnT::Cloner;
use AnT::Range;
use AnT::Analyser;
use AnT::Translator;

use vars qw(@ISA $AUTOLOAD);

@ISA = qw(AnT::Cloner AnT::Translator AnT::Analyser);

{
    my $_class_defaults = {
			   key    => "undefined",
			   str    => undef,
			   qual   => {},
			   ranges => []
			  };

    my $_class_args = {
		       -start  => [qw(_defer start )],
		       -end    => [qw(_defer end   )],
		       -strand => [qw(_defer strand)],
		       -key    => [qw(key    key   )],
		       -ranges => [qw(ranges ranges)],
		       -qual   => [qw(_defer qual  )]
		      };

    sub _class_defaults { $_class_defaults }
    sub _class_args     { $_class_args     }
}

sub AUTOLOAD
{
    my ($self) = @_;

    my $qname = $AUTOLOAD;
    return if $qname =~ /::DESTROY$/;
    $qname =~ s/.*:://;

    if (exists $self->{qual}{$qname})
    {
	unless (ref($self->{qual}{$qname}) eq 'ARRAY')
	{
	    confess "Malformed [$self]: qualifiers not contained in an array"
	}

	# Return the whole list if called inlist context
	return @{${$self->{qual}}{$qname}} if wantarray;

	# Otherwise return just the first element
	return ${${$self->{qual}}{$qname}}[0];
    }
    else
    {
	return
    }
}

=head2 new

 Title   : new
 Usage   : $range = AnT::Feature->new(-start => $start,
         : -end => $end)
 Function: Creates a new AnT::Feature object
 Returns : An AnT::Feature object
 Args    : -key, -strand as strings, -ranges as an array, or a
         : reference to an array and -qual as a hash reference.
         : The -qual argument is meant as a shortcut to add many
         : qualifiers at once. It expects a reference to a hash
         : (keyed on qualifier names) of lists (the corresponding
         : qualifier values). Users are better off with the qadd
         : method (see below) after the object has been created
         : If -start and -end are supplied, an AnT::Range object
         : is implicitly created for these coordinates and
         : attached to the feature. The -ranges and -start/-end
         : arguments are mutually exclusive. If -start/-end are
         : used, both must be supplied.

=cut

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my @args  = @_;

    my $self = {};

    bless($self, $class);

    my $_defaults = $self->_make_defaults;
    my %deferred  = $self->_init($_defaults, @args);

    my ($start, $end, $strand);
    foreach (keys %deferred)
    {
	my $val = $deferred{$_};
	if (/^-start$/)  { $start  = $val; next }
	if (/^-end$/)    { $end    = $val; next }
	if (/^-strand$/) { $strand = $val; next }
	if (/^-qual$/)
	{
	    unless (ref($val) eq 'HASH')
	    {
		confess "Wrong type of argument passed to constructor. You should pass a reference to a hash"
	    }
	    $self->{qual} = $val;
	    next;
	}
    }

    my @ranges = @{$self->{ranges}};

    if (@ranges)
    {
	if (defined $start || defined $end)
	{
	    confess "Both -ranges and -start/-end supplied to constructor"
	}
    }
    else
    {
	if (defined $start && defined $end)
	{
	    my $range = AnT::Range->new(-start => $start, -end => $end);
	    unless ($range)
	    {
		confess "[$self] failed to make valid AnT::Range with " .
		    "arguments -start => $start, -end => $end"
	    }
	    $range->strand($strand) if defined $strand;
	    $self->ranges($range);
	}
	else
	{
	    confess "Neither -ranges nor -start/-end supplied to constructor"
	}
    }
    return $self;
}

=head2 start

 Title   : start
 Usage   : $start = $feature->start;
 Function: Returns the start of the feature from the AnT::Range
         : objects within it
 Returns : Integer
 Args    : None

=cut

sub start
{
    my ($self) = @_;
    my $start;

    if (@{$self->{ranges}})
    {
	# The start of the first range
	$start = ${$self->{ranges}}[0]->start
    }
    return $start;
}

=head2 end

 Title   : end
 Usage   : $end = $feature->end;
 Function: Returns the end of the feature from the AnT::Range
         : objects within it
 Returns : Integer
 Args    : None

=cut

sub end
{
    my ($self) = @_;
    my $end;

    if (@{$self->{ranges}})
    {
	# The end of the last range
	$end = ${$self->{ranges}}[-1]->end
    }
    return $end;
}

=head2 strand

 Title   : strand
 Usage   : $strand = $feature->strand;
         : $feature->strand(-1);
 Function: Returns the feature strand from the AnT::Range objects
         : within it. If there are Range objects on different strands
         : within one feature a strand of 0 will be returned. Given an
         : argument the strand of all Range objects will be set to that
         : value
 Returns : Integer
 Args    : -1, 0 or 1 (optional)

=cut

sub strand
{
    my ($self, $strand) = @_;

    if (defined $strand)
    {
	if ($strand == -1 || $strand == 0 || $strand == 1)
	{
	    foreach ($self->ranges) { $_->strand($strand) }
	}
	else
	{
	    carp "Invalid attempt to set strand of feature [$self] to $strand (use -1, 0 or 1)"
	}
    }
    else
    {
	my $ambiguous;

	my @strands = map{ $_->strand } $self->ranges;
	$strand = shift @strands;

	foreach (@strands)
	{
	    $_ != $strand and $ambiguous++
	}
	if ($ambiguous)
	{
	    carp "Feature [$self] has ranges on both strands: using strand value of 0";
	    $strand = 0;
	}
    }
    return $strand;
}

=head2 type

 Title   : type
 Usage   : $type = $feature->type;
 Function: Returns the sequence type of a feature (the type of sequence
         : to which it is attached)
 Returns : String (dna, rna, protein, virtual)
 Args    : None

=cut

sub type
{
    my ($self) = @_;

    if (! defined $self->{str}{val})
    {
	carp "[$self] is not attached to a sequence";
	return 0;
    }
    elsif (! defined $self->{str}{type})
    {
	carp "The sequence to which [$self] is attached does not have its type defined";
	return 0;
    }
    return $self->{str}{type};
}

=head2 str

 Title   : str
 Usage   : $str = $feature->str;
 Function: Returns the sequence string of a feature
 Returns : String
 Args    : None

=cut

sub str
{
    my ($self) = @_;
    my $str;

    if ($self->strand == 0)
    {
	carp "Unable to get sequence as [$self] has an ambiguous strand value of 0";
    }
    elsif (defined $self->{str}{val})
    {
	my @ranges;
	foreach my $range (@{$self->{ranges}})
	{
	    $str .= substr($self->{str}{val}, ($range->start - 1), ($range->end - $range->start + 1))
	}

	if ($self->strand == -1)
	{
	    # Uracil is converted to Thymine temporarily as there would otherwise
	    # there would be two symbols (T, U) mapped to A in the same tr///
	    # operation
	    $str =~ tr/uU/tT/ if $self->type eq 'rna';
	    $str =~ tr/acgtrymkswhbvdnxACGTRYMKSWHBVDNX/tgcayrkmswdvbhnxTGCAYRKMSWDVBHNX/;
	    $str =~ tr/tT/uU/ if $self->type eq 'rna';
	    $str = reverse $str;
	}
    }
    return $str;
}

=head2 key

 Title   : key
 Usage   : $key = $feature->key;
         : $feature->key($new_key);
 Function: Returns or sets the key of the feature (typically
         : CDS, repeat_unit, misc_feature etc.)
 Returns : String
 Args    : Key as string (optional)

=cut

sub key
{
    my ($self, $key) = @_;

    $self->{key} = $key if defined $key;
    return $self->{key};
}

=head2 has_q

 Title   : has_q
 Usage   : if ($feature->has_q) { print "Feature has qualifiers\n" }
         : print "Feature has ", $feature->has_q('note'), " notes\n";
 Function: Returns the number of qualifiers a feature has, optionally
         : specified with a regular expression
 Returns : Integer or 0
 Args    : Regular expression (optional)

=cut

sub has_q
{
    my ($self, $arg) = @_;

    $arg = '.*' unless defined $arg;

    my $count;
    eval { $count = grep /$arg/, keys %{$self->{qual}} };

    if ($@)
    {
	confess "Bad argument passed to qvalues: $@"
    }
    return $count;
}

=head2 qnames

 Title   : qnames
 Usage   : @qualifiers = $feature->qnames;
 Function: Returns a list of names of the qualifiers attached to
         : the feature
 Returns : List of qualifier names
 Args    : None

=cut

sub qnames
{
    my ($self) = @_;
    return sort keys %{$self->{qual}};
}

=head2 qvalues

 Title   : qvalues
 Usage   : @notes = $feature->qvalues('note');
         : @all   = $feature->qvalues;
 Function: Returns a list of values of qualifiers with names
         : matching a regular expression
 Returns : List of qualifier values
 Args    : Regular expression (optional)

=cut

sub qvalues
{
    my ($self, $arg) = @_;

    $arg = '.*' unless defined $arg;

    my (@names, @values);
    eval { @names  = grep /$arg/, keys %{$self->{qual}} };

    if ($@)
    {
	confess "Bad argument passed to qvalues: $@"
    }
    else
    {
	# The line noise represents (left to right):
	# @{  block dereference array ref
	# ${  block dereference hash ref (in AnT::Feature hash)
	@values = map { @{${$self->{qual}}{$_}} } @names;

	# Some qualifiers have no content (i.e. are just flags
	# like /pseudo). This removes their undef values from
	# the list
	@values = grep {defined $_} @values;	
    }
    return @values;
}

=head2 qadd

 Title   : qadd
 Usage   : $feature->qadd('note', $note1, $note2);
         : $feature->qadd('note', @notes);
         : $feature->qadd('pseudo');
 Function: Adds a qualifier with an optional value field
 Returns : Nothing
 Args    : Qualifier name as string, qualifier values as a string
         : or list of strings (optional)

=cut

sub qadd
{
    my ($self, $name, @args) = @_;

    return 0 unless defined $name;

    foreach (@args)
    {
	if (exists ${$self->{qual}}{$name})
	{
	    push(@{${$self->{qual}}{$name}}, $_)
	}
	else
	{
	    ${$self->{qual}}{$name} = [$_]
	}
    }
}

=head2 qremove

 Title   : qremove
 Usage   : $feature->qremove('note');
 Function: Removes qualifiers (and values) with names matching
         : a regular expression (using grep). With no argument
         : it removes all qualifiers
 Returns : List of removed values
 Args    : Regular expression (optional)

=cut

sub qremove
{
    my ($self, $arg) = @_;

    $arg = '.*' unless defined $arg;

    my (@names, @values);
    eval { @names  = grep /$arg/, keys %{$self->{qual}} };

    if ($@)
    {
	confess "Bad argument passed to qremove: $@"
    }
    else
    {
	# The line noise represents (left to right):
	# @{  block dereference array ref
	# ${  block dereference hash ref (in AnT::Feature hash)
	@values = map { @{${$self->{qual}}{$_}} } @names;

	foreach (@names)
	{
	    delete(${$self->{qual}}{$_})
	}
    }
    return @values;
}

=head2 has_ranges

 Title   : has_ranges
 Usage   : if ($feat->has_ranges) { print "Feature has ranges\n" };
         : print "Feature has ", $feat->has_features, " ranges\n";
 Function: Returns the number of ranges on an AnT::Feature object
 Returns : Integer, or 0
 Args    : None

=cut

sub has_ranges
{
    my ($self) = @_;
    return scalar @{$self->{ranges}};
}


=head2 ranges

 Title   : ranges
 Usage   : $feature->ranges($range1, $range2, $range3);
         : $feature->ranges(@ranges);
 Function: Returns or adds AnT::Range objects to a feature. If
         : the feature is currently attached to a sequence each
         : range is validated first
 Returns : Nothing
 Args    : AnT::Range objects, either as an array, or a reference
         : to an array

=cut

sub ranges
{
    my ($self, @ranges) = @_;

    # Expand array references into a copy of the array
    @ranges = map { if (ref($_) eq 'ARRAY') { @$_ } else { $_ } } @ranges;

    foreach (@ranges)
    {
	push(@{$self->{ranges}}, $_) if $self->_valid_range($_)
    }

    $self->_sort_ranges(@{$self->{ranges}});
    return @{$self->{ranges}};
}

=head2 overlaps

 Title   : overlaps
 Usage   : if ($feature1->overlaps($feature2)) { print "They overlap\n" }
         : if ($feature1->overlaps(@features)) { print "They overlap\n" }
 Function: Returns true if a feature overlaps one or more other features
 Returns : False or number of features overlapping this object
 Args    : AnT::Feature object(s)

=cut

sub overlaps
{
    my ($self, @features) = @_;

    my $total = 0;
    foreach my $feature (@features)
    {
	my $overlap = 0;
	foreach my $range ($self->ranges)
	{
	    # Return true even if only one range passes test
	    $overlap++ if $range->overlaps($feature->ranges)
	}
	$total++ if $overlap;
    }
    return $total;
}

=head2 contains

 Title   : contains
 Usage   : if ($feature1->contains($feature2)) { print "1 contains 2\n" }
         : if ($feature1->contains(@features)) { print "1 contains all\n" }
 Function: Returns true if a feature contains one or more other features.
         : The contained feature's ranges must all be within ranges of
         : this object
 Returns : False or the number of features contained by this object
 Args    : AnT::Feature object(s)

=cut

sub contains
{
    my ($self, @features) = @_;

    my $total = 0;
    foreach my $feature (@features)
    {
	my $check = $feature->has_ranges;
	foreach my $range ($self->ranges)
	{
	    # Return false if any range fails test
	    $check-- if ($range->contains($feature->ranges))
	}
	$total++ unless $check;
    }
    return $total;
}

=head2 spans

 Title   : spans
 Usage   : if ($feature1->spans($feature2)) { print "1 spans 2\n" }
         : if ($feature1->spans(@features)) { print "1 spans all\n" }
 Function: Returns true if a feature spans one or more other features
         : The spanned feature's ranges must lie somewhere between the
         : start of this object's first range and the end of its last
         : range
 Returns : False or the number of features spanned by this object
 Args    : AnT::Feature object(s)

=cut

sub spans
{
    my ($self, @features) = @_;

    my $f_start = $self->start;
    my $f_end   = $self->end;

    my $total = 0;
    foreach my $feature (@features)
    {
	my $span = 0;
	foreach my $range ($feature->ranges)
	{
	    my $r_start = $range->fuzzy_start || $range->start;
	    my $r_end   = $range->fuzzy_end   || $range->end;

	    $span++ if (($r_start >= $f_start) && ($r_end <= $f_end))
	}
	$total++ if $span;
    }
    return $total;
}

=head2 _sort_ranges

 Title   : _sort_ranges
 Usage   : N/A
 Function: Sorts AnT::Range objects within a feature into order of
         : ascending start coordinate
 Returns : Nothing
 Args    : None

=cut

sub _sort_ranges
{
    my ($self, @args) = @_;
    @{$self->{ranges}} = sort { $a->start <=> $b->start } @args;
}

=head2 _valid_range

 Title   : _valid_range
 Usage   : N/A
 Function: Checks that an AnT::Range object within a feature falls
         : within the boundaries of any Seq object to which the
         : feature is attached. If the Seq object is virtual,
         : there are effectively no boundaries
 Returns : 1 if valid range
 Args    : AnT::Range object

=cut

sub _valid_range
{
    my ($self, $range) = @_;

    unless ($range->start or $range->fuzzy_start)
    {
	carp "Malformed [$range] in [$self] has start of 0 or undef";
	return;
    }
    unless ($range->end or $range->fuzzy_end)
    {
	carp "Malformed [$range] in [$self] has end of 0 or undef";
	return;
    }

    if (defined $self->{str}{val})
    {
	my $seqlen = length($self->{str}{val});

	if ($range->start < 0 or $range->start > $seqlen)
	{
	    carp "[$range] in [$self] has start out of range";
	    return;
	}
	if ($range->end < 0 or $range->end > $seqlen)
	{
	    carp "[$range] in [$self] has end out of range";
	    return;
	}
    }
    return 1;
}

=head2 clone [inherited from AnT::Cloner]

 Title   : clone
 Usage   : $object = AnT::<object>->clone(args)
 Function: Creates a new AnT::<object> from an existing one. The
         : new object is a copy and is not a reference to the same
         : bit of memory as the cloning object. Object attributes
         : may be changed in the clone by passing arguments to the
         : clone method as if it were the constructor (new method)
 Returns : An AnT::<object>
 Args    : Same as for constructor

=cut

=head2 translate [inherited from AnT::Translator]

 Title   : translate
 Usage   : $protein = $feature->translate;
         : $aa = $nt->translate(1);
 Function: Translates the sequence of both AnT::Seq and AnT::Feature
         : objects
 Returns : A new AnT::Seq object
 Args    : Translation table id number, frame and N-terminal flag,
         : in that order
         :
         : The translation table numbering system is the usual one;
         : 1, Standard; 2, Vertebrate mitochondrial; 3, Yeast
         : mitochondrial etc. The N-terminal flag determines
         : whether the first codon is treated as a start codon. Set
         : this to 0 if you don't want this (the default is 1)
         : If the caller is an AnT::Feature object, this method will
         : automatically honour any codon_start qualifiers it may
         : have. These override the frame argument to the method
         :
         : Translate is a 'lite' method and will return an amino
         : acid 'X' where there is an ambiguous base in a codon

=cut

=head2 composition [inherited from AnT::Analyser]

 Title   : composition
 Usage   : my %comp = $self->composition;
         : Then $a = $comp{a} to get a count of residue 'a'. If
         : you try $x = $comp{x} and there are no 'x' residues
         : in the sequence, the result will of course be undef
 Function: Returns a hash with the constituent residues of the
         : sequence as keys and their corresponding frequency
         : as values. All the keys are upper case
 Returns : Hash
 Args    : None

=cut

1;






