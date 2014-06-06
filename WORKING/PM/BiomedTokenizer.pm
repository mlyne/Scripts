package BMTok;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(tokenize stem);

# written by Vetle I. Torvik and Marc Weeber
#
# Copyright 2007, University of Illinois at Chicago

sub tokenize {
    #input a string of words
    my $ti = shift;

    # add initial and final space
    $ti = " $ti ";
    # optimize regexp with study (12% speed increase)
    study $ti;
    # 1: make it all lowercase
    $ti = lc $ti;
    # 2: replace parentheses and punctuation by spaces
    $ti =~ s/[\[\](),\.\";:!?&\^\/\*]/ /g;
    # 3: remove --
    $ti =~ s/--+/ /g;
    # 4: hyphenation: replace by " " only before non-digit + ' and after non-digit
    $ti =~ s/([^\d\'])-([^\d])/$1 $2/g;
    # 5a: remove 's
    $ti =~ s/\'s / /g;
    # 5b:  ' : replace by " " only after non-digit
    $ti =~ s/([^\d])\'/$1 /g;
    # 6: remove words without any alpahabetical thingie (numbers, 100% +/-, etc)
    $ti =~ s/ [^a-z]+ / /g;
    # 7: some details
    $ti =~ s/ [^ ]+-(year|yr|month|week|day|hour|second) / /g;
    # umpieth
    $ti =~ s/ \d+th / /g;
    # cleanup:
    #8: remove non-alphanumerics in beginning and end (lots of chemical names that were split)
    #     deleterious to short things ending with + (e.g. na2+ k+)
    $ti =~ s/ ([^a-z0-9]+)/ /g;
    $ti =~ s/[^a-z0-9]+ / /g;
    # 9: remove more than one space
    $ti =~ s/  +/ /g;
    # 10: remove initial and trailing spaces
    $ti =~ s/^ +//;
    $ti =~ s/ +$//;
    
    return $ti;
}


sub stem {
    #input a word
    my $w = shift;

    #British spelling -our
    $w =~ s/(tum|vap|odo|lab|behavi|flav|harb|fav|hon|col|rum|vig)our/$1or/g;
    #some Latin
    #  convert plural -ae to e: minimal matching using ? more efficient?
    $w =~ s/([a-z]{3,}?a)e$/$1/g;
    #  convert oe- to e- except oedipus (would be nice to replace all oe's ecept coe ?)
    $w =~ s/^o(e[a-z]{3,}?)/$1/g and $w =~ s/^(edipus|edipal)/^o$1/g;	    
    #consider chopping -s on words consisting entirely of alphabetical characters
    if ($w =~ /^[a-z]+s$/) {
	if (length( $w ) < 5) {
	    $w =~ s/^(rat|dog|cat|ray|egg|cow|eye|age|use|boy|jaw|dye|fat|way|law|hen|leg|gel|bed|bat|ear|rod|sow|arm|pig|tip|end|ion|oil|toe|lip|day|fee|hit|gum|aim|sin|hog|act|eeg|jew|map|job|rib|war|art|kit|oat|see|sea|bee|put|spa|toy|add|bud|pen|net|set|cue|get|jar|fit|bag|pup|one|pad|bar|car|cut|dot|lie|ant|bid|bin|hip|key|joy|lab|lid|nun|mri|pie|die|ewe|eel)s$/$1/;
	}
	else{
	    #don't mess with -ss, -us, -is, -phos
	    $w =~ /(ss|us|is|phos)$/ or
	    #some special -es
	    $w =~ s/(ss|x|sh)es$/$1/ or
	    $w =~ s/(virus|fetus|foetus|sinus|lens|atlas|iris|census|genus|penis|focus|callus)es$/$1/ or
	    $w =~ s/(hypothes|cris|neuros|psychos|test|synthes|pelv)es$/$1is/ or
	    # some special -ies
	    $w =~ /(species|caries|facies|series|rabies)$/ or
	    $w =~ s/(zombie|calorie|hippie|prairie|movie)s$/$1/ or
	    #default -ies -> y
	    $w =~ s/ies$/y/ or
	    # -ches -> -ch, but NOT niches, avalanches, toothaches, creches, bouches, douches, psyches, caches etc
	    $w =~ s/((ee|[eo]a|ri|r|t|([^a][^l][^a]n)|[^db]ou)ch)es$/$1/ or
	    #some special -s to keep
	    $w =~ /(propos|always|afterwards|perhaps|whereas|selves|accumbens|meninges|ambiens|annectens|abducens|oriens|reuniens|ascendens|pancreas|saccharomyces|texas|diabetes|herpes|feces|faeces|elegans|deferens|kansas|angeles)$/ or
	    # default, chop -s
	    $w =~ s/s$//;
	}
    }
    return $w;
}
1;