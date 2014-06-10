#!/usr/bin/perl -w

use strict;
use warnings;
use XML::Twig;

our @results;      # <= put results in here

sub parse_a_counter {
    my ($type) = @_;

    # return closure over type
    return sub {
        my ($twig, $counter) = @_;
        my @report = $counter->children(qq{report [\@type="$type"]});
        for my $reportingInterval (@report){
            my @stringSet = $reportingInterval->children(qq{stringSet[\@index]});
            for my $stringSet (@stringSet){
                    my @string_list = $stringSet->children_text('string');
                    push @results, \@string_list;
            }
        }
        $counter->purge; # free the memory of $counter
    }; # end of return sub
}

my @counter_name = qw/music xmusic/;
foreach my $counter_name (@counter_name){
    my $roots = { qq{counter[\@name="$counter_name"]} => 1 };
    my $handlers = { counter => parse_a_counter("month") };
    my $twig = new XML::Twig(TwigRoots => $roots,
             TwigHandlers => $handlers);
    $twig->parsefile('callback.xml');
    # got the string list now:
    for my $myresults (@results){
            print @{$myresults}; # will replace print with sth. to process the results
    }
    my $nums = @results;
    while ($nums --){
            pop(@results);
    }
    print qq{finish process in counter name $counter_name \n\n};

}