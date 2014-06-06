sub exactmatchp {
    my( $pos1, $pos2) = @_;
    return ($hword[$pos1] eq $vword[$pos2]);
};

sub lcsrcogp {
# assumes global @hword, @vword, and $MINCLR
    my( $pos1, $pos2) = @_;

    my($word1) = $hword[$pos1];
    my($word2) = $vword[$pos2];

    $word1 =~ s/::[^:]+$//;
    $word2 =~ s/::[^:]+$//;
# lowercasing done by &norm on axis input
#    $word1 =~ tr/A-Z/a-z/;
#    $word2 =~ tr/A-Z/a-z/;
    if ($word1 eq $word2) {
	return $TRUE;
    };

    my($l1) = length($word1);
    my($l2) = length($word2);
    if ($l1 < 4 or $l2 < 4) {
	return $FALSE;
    };

#    if (substr($word1, 0, $MISL) ne substr($word2, 0, $MISL)) {
#	return $FALSE;
#    };
    
    my($lcsl) = &string_lcs($word1, $word2);
    if ($l1 > $l2) {
	if ($lcsl / $l1 < $MINCLR) {
	    return $FALSE;
	};
    } else {
	if ($lcsl / $l2 < $MINCLR) {
	    return $FALSE;
	};
    };

    return $TRUE;
};

sub lcsrcogp2 {
# assumes global $MINLCSR
    my( $word1, $word2) = @_;

    if ($word1 eq $word2) {
	return $TRUE;
    };

    my($l1) = length($word1);
    my($l2) = length($word2);
    if ($l1 < 4 or $l2 < 4) {
	return $FALSE;
    };

    my($lcsl) = &string_lcs($word1, $word2);
    if ($l1 > $l2) {
	if ($lcsl / $l1 < $MINLCSR) {
	    return $FALSE;
	};
    } else {
	if ($lcsl / $l2 < $MINLCSR) {
	    return $FALSE;
	};
    };

    return $TRUE;
};

sub simplecogp {
# assumes global @hword, @vword, $MINCLR and $MISL
    my( $pos1, $pos2) = @_;
    my($l1, $l2, $word1, $word2);

    $word1 = $hword[$pos1];
    $word2 = $vword[$pos2];

    if ($word1 eq $word2) {
	return $TRUE;
    };

    $l1 = length($word1);
    $l2 = length($word2);
    if ($l1 < 4 or $l2 < 4) {
	return $FALSE;
    };
    if ($l1 > $l2) {
	if ($l2 / $l1 < $MINCLR) {
	    return $FALSE;
	};
    } else {
	if ($l1 / $l2 < $MINCLR) {
	    return $FALSE;
	};
    };

    if (substr($word1, 0, $MISL) eq substr($word2, 0, $MISL)) {
	return $TRUE;
    };
    
    return $FALSE
};

sub toktagmatch {
# extracts tags from tokens and calls &tagmatch    
    my($tokA, $tokB) = @_;
    
    $tagA = &gettag($tokA);
    $tagB = &gettag($tokB);

    return &tagmatch($tagA, $tagB);
};

sub gettag {
    my($tok) = shift;
    if ($tok =~ /.+::([^:]+)/) {
	return $1;
    };

    die "gettag: bad token: $tok\n";
};    


sub tagmatch {
    my($tagA, $tagB) = @_;

    return ($tagA eq $tagB
	    || (" J VBN VBG " =~ $tagA && " J VBN VBG " =~ $tagB
		&& $tagA ne "V" && $tagB ne "V"
		&& $tagA ne "N" && $tagB ne "N" )
	    || ($tagA eq "RP" && $tagB eq "IN")
	    || ($tagB eq "RP" && $tagA eq "IN")
	    || ($tagA eq "NP" && $tagB eq "N")
	    || ($tagB eq "NP" && $tagA eq "N")
	    || ($tagA eq "CD" && $tagB eq "D")
	    || ($tagB eq "CD" && $tagA eq "D")
	    || ($tagA eq "P" && $tagB eq "D")
	    || ($tagB eq "P" && $tagA eq "D")
	    || $tagA eq "UK"
	    || $tagB eq "UK");

};


sub breakpunctp {
    return ($_[0] =~ /[^\-]::EO[PS]/ or
	    $_[0] =~ /::SCM/);
};

sub functionclassp {
    return ($_[0] =~ /::[FDCPIE]/ or $_[0] =~ /::UH/ or $_[0] =~ /::SCM/);
};

sub contentclassp {
    return ($_[0] =~ /::[ONVJR]/ or $_[0] =~ /::UK/ or $_[0] =~ /::SYM/);
};

sub norm_hansard {
    my($w) = shift;
  
    # remove Hansard-style accents
    $w =~ s/\^.//g;
    # lowercase
    $w =~ y/A-Z/a-z/;

    return $w;
};

sub norm {
    my($w) = shift;

    $w = &norm_nolower($w);

    # lowercase
    $w =~ y/A-Z/a-z/;

    return $w;
};

sub norm_nolower {
    my($w) = shift;
    
    $w =~ s/À/A/g;
    $w =~ s/Á/A/g;
    $w =~ s/Â/A/g;
    $w =~ s/Ã/A/g;
    $w =~ s/Ä/A/g;
    $w =~ s/Å/A/g;
    $w =~ s/Ç/C/g;
    $w =~ s/È/E/g;
    $w =~ s/É/E/g;
    $w =~ s/Ê/E/g;
    $w =~ s/Ë/E/g;
    $w =~ s/Î/I/g;
    $w =~ s/Í/I/g;
    $w =~ s/Ì/I/g;
    $w =~ s/Ï/I/g;
    $w =~ s/Ñ/N/g;
    $w =~ s/Ô/O/g;
    $w =~ s/Ò/O/g;
    $w =~ s/Ó/O/g;
    $w =~ s/Õ/O/g;
    $w =~ s/Ö/O/g;
    $w =~ s/Ø/O/g;
    $w =~ s/Û/U/g;
    $w =~ s/Ú/U/g;
    $w =~ s/Ù/U/g;
    $w =~ s/Ü/U/g;
    $w =~ s/à/a/g;
    $w =~ s/â/a/g;
    $w =~ s/ä/a/g;
    $w =~ s/á/a/g;
    $w =~ s/å/a/g;
    $w =~ s/æ/ae/g;
    $w =~ s/ç/c/g;
    $w =~ s/è/e/g;
    $w =~ s/é/e/g;
    $w =~ s/ê/e/g;
    $w =~ s/ë/e/g;
    $w =~ s/î/i/g;
    $w =~ s/í/i/g;
    $w =~ s/ì/i/g;
    $w =~ s/ï/i/g;
    $w =~ s/ñ/n/g;
    $w =~ s/ô/o/g;
    $w =~ s/ó/o/g;
    $w =~ s/ò/o/g;
    $w =~ s/ö/o/g;
    $w =~ s/ø/o/g;
    $w =~ s/ß/ss/g;
    $w =~ s/ù/u/g;
    $w =~ s/ú/u/g;
    $w =~ s/û/u/g;
    $w =~ s/ü/u/g;
    $w =~ s/ÿ/y/g;

    return $w;
};

sub cogdictposp {
# assumes global %trans, @hword, @vword, @htag, @vtag, $MINCLR
    my( $pos1, $pos2) = @_;
    my($l1, $l2, $word1, $word2, $tag1, $tag2, $tr);

    $tag1 = $htag[$pos1];
    $tag2 = $vtag[$pos2];

    # reject if tags don't match
    if (not &tagmatch($tag1, $tag2)) {
	return $FALSE;
    };

    return &cogdictp($pos1, $pos2);
};

sub cogdictp {
# assumes global %trans, @hword, @vword, $MINCLR
    my( $pos1, $pos2) = @_;
    my($l1, $l2, $word1, $word2, $tag1, $tag2, $tr);

    $word1 = $hword[$pos1];
    $word2 = $vword[$pos2];

    # if either word is in the tralex, 
    # then only accept if the other is a valid translation
    if (defined $htrans{$word1} and defined $vtrans{$word2}) {
	if ($#{$htrans{$word1}} > $#{$vtrans{$word2}}) {
	    foreach $tr (@{$vtrans{$word2}}) {
		if ($tr eq $word1) {
		    return $TRUE;
		};
	    };
	} else {
	    foreach $tr (@{$htrans{$word1}}) {
		if ($tr eq $word2) {
		    return $TRUE;
		};
	    };
	};
	return $FALSE;
    } elsif (defined $htrans{$word1} or defined $vtrans{$word2}) {
	return $FALSE;
    };

    # otherwise use cognate criterion
    return &lcsrcogp($pos1, $pos2);
};


sub dictmatchp {
# assumes global %trans, @hword, @vword
    my( $pos1, $pos2) = @_;
    my($l1, $l2, $word1, $word2, $tag1, $tag2, $tr);

    $word1 = $hword[$pos1];
    $word2 = $vword[$pos2];

    # if either word is in the tralex, 
    # then only accept if the other is a valid translation
    if (defined $htrans{$word1} and defined $vtrans{$word2}) {
        if ($#{$htrans{$word1}} > $#{$vtrans{$word2}}) {
            foreach $tr (@{$vtrans{$word2}}) {
                if ($tr eq $word1) {
                    return $TRUE;
                };
            };
        } else {
            foreach $tr (@{$htrans{$word1}}) {
                if ($tr eq $word2) {
                    return $TRUE;
                };
            };
        };
    };

    return $FALSE;
};


sub dict_or_exact_matchp {
# assumes global %trans, @hword, @vword
    my( $pos1, $pos2) = @_;
    my($l1, $l2, $word1, $word2, $tag1, $tag2, $tr);

    $word1 = $hword[$pos1];
    $word2 = $vword[$pos2];

    # if either word is in the tralex, 
    # then only accept if the other is a valid translation
    if (defined $htrans{$word1} and defined $vtrans{$word2}) {
	if ($#{$htrans{$word1}} > $#{$vtrans{$word2}}) {
	    foreach $tr (@{$vtrans{$word2}}) {
		if ($tr eq $word1) {
		    return $TRUE;
		};
	    };
	} else {
	    foreach $tr (@{$htrans{$word1}}) {
		if ($tr eq $word2) {
		    return $TRUE;
		};
	    };
	};
    } elsif (defined $htrans{$word1} or defined $vtrans{$word2}) {
	return $FALSE;
    };

    return ($word1 eq $word2);
};


sub cogdictp2 {
# assumes global %trans, $MINLCSR
    my( $word1, $word2) = @_;
    my($l1, $l2, $tag1, $tag2, $tr);

    # if either word is in the tralex, 
    # then only accept if the other is a valid translation
    if (defined $htrans{$word1} and defined $vtrans{$word2}) {
	if ($#{$htrans{$word1}} > $#{$vtrans{$word2}}) {
	    foreach $tr (@{$vtrans{$word2}}) {
		if ($tr eq $word1) {
		    return $TRUE;
		};
	    };
	} else {
	    foreach $tr (@{$htrans{$word1}}) {
		if ($tr eq $word2) {
		    return $TRUE;
		};
	    };
	};
	return $FALSE;
    } elsif (defined $htrans{$word1} or defined $vtrans{$word2}) {
	return $FALSE;
    };

    # otherwise use cognate criterion
    return &lcsrcogp2($word1, $word2);
};

sub Estem_tagged {
# stems a tagged English word
    my($tok) = shift;
    
    my($word, $tag) = split('::', $tok);

    $word = &norm_nolower($word);

    # if not proper noun, then lowercase it
    if ($tag ne "NP") {
	$word =~ tr/A-Z/a-z/;
    };
    # remove 's/is dichotomy when possible
    if ($tag eq "V" && $word eq "\'s") {
	$word = "be";
    };
    my($lword) = $word;
    $lword =~ s/(\W)/\\$1/g;
    my($db) = qx{ echo "$word" | findmorph $lib/morph_english.db };
    if ($db =~ /^\*\*NOT FOUND \*\* $lword/) {
	return "$word"."::"."$tag";
    } elsif ( $db =~ /$lword (.*)/) {
	my($ss) = $1;
	my(@stems) = split('#', $ss);
	my($stem, @sparts);
	foreach $stem (@stems) {
	    $stem =~ s/\t/ /g;
	    $stem =~ s/^ *//;
	    $stem =~ s/ *$//;
	    @sparts = split(/\s+/, $stem);
	    if (($sparts[1] eq "Conj" && $tag eq "CJ")
		||  ($sparts[1] eq "Det" && $tag eq "D")
		||  ($sparts[1] eq "Prep" && $tag eq "IN")
		||  ($sparts[1] eq "A" && $tag eq "J")
		||  ($sparts[1] eq "N" && $tag eq "N")
		||  ($sparts[1] eq "NP" && $tag eq "NP")
		||  ($sparts[1] eq "Pron" && $tag eq "P")
		||  ($sparts[1] eq "Adv" && $tag eq "R")
		||  ($sparts[1] eq "V" && $tag eq "VBN" 
		     && $sparts[2] eq "PPART" )
		||  ($sparts[1] eq "V" && $tag eq "VBG" 
		     && $sparts[2] eq "PROG" )
		||  ($sparts[1] eq "V" && $tag eq "V" 
		     && $sparts[2] ne "PROG" && $sparts[2] ne "PPART" )) {
		# remove weird XTAG diacritics
		$sparts[0] =~ s/[_\^]//g;
		return "$sparts[0]"."::"."$tag";
	    };
	};
	return "$word"."::"."$tag";
    } else {
	die "DB lookup error, line $.: $db";
    };
};


sub Estem_untagged {
# stems an untagged English word
    my($w) = shift;

    $w =~ s/::[^:]+$//;
    $w = &norm($w);
    
    my($dbout) = qx{ echo "$w" | findmorph $lib/morph_english.db };
    return &parsemorph($dbout);
};

sub parsemorph {
# subroutine version of parsemorph.pl
    $_ = shift;

    my($inflected, $lemmas, @rest, @set, $set, @POS);

    /([^ ]+) (.+)/;
    $inflected = $1;
    $lemmas = $2;
    if ($inflected eq "**NOT") {
	# not in DB
	@rest = split(' ', $lemmas);
	return $rest[2];
    } elsif ($inflected !~ /^[A-Za-z]/) {
	# punctuation
	return $inflected;
    } else {
	@set = split('#', $lemmas);
        # see if there's a verb entry
	foreach $set (@set) {
	    ($lemma, @POS) = split(' ', $set);
	    if ($POS[0] eq "V") {
		return $lemma;
	    };
	};
    };
    
    # no verb entry; use first entry
    ($lemma, @POS) = split(' ', $set[0]);
    return $lemma;
};

sub Fstem_tagged {
# assumes stemming lexicon has been loaded into %stem
# open-class words except proper nouns are stemmed,
#	as well as clitics and complex prepositions
# takes a guess for words not in the lexicon
    my($wt) = shift;

    if ($wt =~ /(.+)::([^: ]+)/) {
	my($word) = $1;
	my($tag) = $2;
    } else {
	die "Bad Token: $wt, line $.\n";
    };
    if ($tag eq "NP") {
	return $wt;
	next;
    };	
    
    # proper nouns have been filtered, everything else can be lowercased
    $word =~ tr/A-Z/a-z/;
    # stem clitics
    if ($word eq "c^c\'") { 
	$word = "c^ca";
    } elsif ($word eq "s\'") { 
	if ($tag eq "CJ" or $tag eq "R") {
	    $word = "si";
	} else {
	    $word = "se";
	};
    } else {
	$word =~ s/(.)\'$/$1e/;
    };

    $wt = "$word:-:$tag";

    if (defined($stem{$wt})) {
	return $stem{$wt}."::".$tag;
    } else {
	my($st) = $word;
	if (length($word) > 3) {
	    my(@chars) = split("", reverse $word);
	    if ($tag eq "V") {
		if (join("", @chars[0..6]) eq "tneiare") {
		    $st = substr($word, 0, length($word) - 7);
		} elsif (join("", @chars[0..6]) eq "tnerg^e") {
		    $st = substr($word, 0, length($word) - 7);
		} elsif (join("", @chars[0..6]) eq "snorg^e") {
		    $st = substr($word, 0, length($word) - 7);
		} elsif (join("", @chars[0..5]) eq "snoire") {
		    $st = substr($word, 0, length($word) - 6);
		} elsif (join("", @chars[0..4]) eq "siass") {
		    $st = substr($word, 0, length($word) - 5);
		} elsif (join("", @chars[0..4]) eq "zeire") {
		    $st = substr($word, 0, length($word) - 5);
		} elsif (join("", @chars[0..4]) eq "tneia") {
		    $st = substr($word, 0, length($word) - 5);
		} elsif (join("", @chars[0..4]) eq "snore") {
		    $st = substr($word, 0, length($word) - 5);
		} elsif (join("", @chars[0..4]) eq "tnore") {
		    $st = substr($word, 0, length($word) - 5);
		} elsif (join("", @chars[0..4]) eq "tnori") {
		    $st = substr($word, 0, length($word) - 5);
		} elsif (join("", @chars[0..4]) eq "siare") {
		    $st = substr($word, 0, length($word) - 5);
		} elsif (join("", @chars[0..4]) eq "tiare") {
		    $st = substr($word, 0, length($word) - 5);
		} elsif (join("", @chars[0..4]) eq "snoss") {
		    $st = substr($word, 0, length($word) - 5);
		} elsif (join("", @chars[0..4]) eq "tness") {
		    $st = substr($word, 0, length($word) - 5);
		} elsif (join("", @chars[0..3]) eq "zess") {
		    $st = substr($word, 0, length($word) - 4);
		} elsif (join("", @chars[0..3]) eq "snos") {
		    $st = substr($word, 0, length($word) - 4);
		} elsif (join("", @chars[0..3]) eq "zere") {
		    $st = substr($word, 0, length($word) - 4);
		} elsif (join("", @chars[0..3]) eq "iare") {
		    $st = substr($word, 0, length($word) - 4);
		} elsif (join("", @chars[0..3]) eq "sare") {
		    $st = substr($word, 0, length($word) - 4);
		} elsif (join("", @chars[0..3]) eq "snoi") {
		    $st = substr($word, 0, length($word) - 4);
		} elsif (join("", @chars[0..3]) eq "tnor") {
		    $st = substr($word, 0, length($word) - 4);
		} elsif (join("", @chars[0..3]) eq "siar") {
		    $st = substr($word, 0, length($word) - 4);
		} elsif (join("", @chars[0..2]) eq "ess") {
		    $st = substr($word, 0, length($word) - 3);
		} elsif (join("", @chars[0..2]) eq "sio") {
		    $st = substr($word, 0, length($word) - 3);
		} elsif (join("", @chars[0..2]) eq "tio") {
		    $st = substr($word, 0, length($word) - 3);
		} elsif (join("", @chars[0..2]) eq "rio") {
		    $st = substr($word, 0, length($word) - 3);
		} elsif (join("", @chars[0..2]) eq "iar") {
		    $st = substr($word, 0, length($word) - 3);
		} elsif (join("", @chars[0..2]) eq "zei") {
		    $st = substr($word, 0, length($word) - 3);
		} elsif (join("", @chars[0..2]) eq "are") {
		    $st = substr($word, 0, length($word) - 3);
		} elsif (join("", @chars[0..2]) eq "sno") {
		    $st = substr($word, 0, length($word) - 3);
		} elsif (join("", @chars[0..2]) eq "tne") {
		    $st = substr($word, 0, length($word) - 3);
		} elsif (join("", @chars[0..2]) eq "sia") {
		    $st = substr($word, 0, length($word) - 3);
		} elsif (join("", @chars[0..2]) eq "tia") {
		    $st = substr($word, 0, length($word) - 3);
		} elsif (join("", @chars[0..1]) eq "ri") {
		    $st = substr($word, 0, length($word) - 2);
		} elsif (join("", @chars[0..1]) eq "re") {
		    $st = substr($word, 0, length($word) - 2);
		} elsif (join("", @chars[0..1]) eq "er") {
		    $st = substr($word, 0, length($word) - 2);
		} elsif (join("", @chars[0..1]) eq "ze") {
		    $st = substr($word, 0, length($word) - 2);
		} elsif (join("", @chars[0..1]) eq "se") {
		    $st = substr($word, 0, length($word) - 2);
		} elsif (join("", @chars[0..1]) eq "sa") {
		    $st = substr($word, 0, length($word) - 2);
		} elsif ($chars[0] eq "a") {
		    $st = substr($word, 0, length($word) - 1);
		} elsif ($chars[0] eq "e") {
		    $st = substr($word, 0, length($word) - 1);
		} elsif ($chars[0] eq "t") {
		    $st = substr($word, 0, length($word) - 1);
		} elsif ($chars[0] eq "s") {
		    $st = substr($word, 0, length($word) - 1);
		};
	    } elsif ($tag eq "N") {
		if ($chars[0] eq "s") {
		    $st = substr($word, 0, length($word) - 1);
		} elsif ($chars[0].$chars[1] eq "xu") {
		    $st = substr($word, 0, length($word) - 1);
		};
	    } elsif ($tag eq "J" || $tag eq "VBN") {
		if ($chars[0].$chars[1] eq "se") {
		    $st = substr($word, 0, length($word) - 2);
		} elsif ($chars[0].$chars[1] eq "xu") {
		    $st = substr($word, 0, length($word) - 1);
		} elsif ($chars[0] eq "s") {
		    $st = substr($word, 0, length($word) - 1);
		} elsif ($chars[0] eq "e") {
		    $st = substr($word, 0, length($word) - 1);
		};
	    };
	};

	return $st."::".$tag;
    };
};

sub penn2idm {
# also handles Brown corpus tags
    my($tag) = shift;

    if ($tag =~ /\"/) { return "SCM";}
    elsif ($tag =~ /\#/) { return "SYM";}
    elsif ($tag =~ /\'\'/) { return "SCM";}
    elsif ($tag =~ /\(/) { return "SCM";}
    elsif ($tag =~ /\)/) { return "SCM";}
    elsif ($tag =~ /\,/) { return "EOP";}
    elsif ($tag =~ /\-\-/) { return "EOP";}
    elsif ($tag =~ /\./) { return "EOS";}
    elsif ($tag =~ /:/) { return "EOP";}
    elsif ($tag =~ /CC/) { return "CJ";}
    elsif ($tag =~ /CD/) { return "CD";}
    elsif ($tag =~ /EX/) { return "P";}
    elsif ($tag =~ /FW/) { return "UK";}
    elsif ($tag =~ /IN/) { return "IN";}
    elsif ($tag =~ /JJR/) { return "J";}
    elsif ($tag =~ /JJSS/) { return "J";}
    elsif ($tag =~ /JJS/) { return "J";}
    elsif ($tag =~ /JJ/) { return "J";}
    elsif ($tag =~ /LS/) { return "CD";}
    elsif ($tag =~ /MD/) { return "V";}
    elsif ($tag =~ /NP/) { return "NP";}
    elsif ($tag =~ /NNS/) { return "N";}
    elsif ($tag =~ /NN/) { return "N";}
    elsif ($tag =~ /PDT/) { return "D";}
    elsif ($tag =~ /POS/) { return "P";}
    elsif ($tag =~ /PRP\$/) { return "D";}
    elsif ($tag =~ /PRP/) { return "P";}
    elsif ($tag =~ /PP/) { return "P";}
    elsif ($tag =~ /RBR/) { return "R";}
    elsif ($tag =~ /RBS/) { return "R";}
    elsif ($tag =~ /SYM/) { return "SYM";}
    elsif ($tag =~ /TO/) { return "IN";}
    elsif ($tag =~ /UH/) { return "UH";}
    elsif ($tag =~ /VBD/) { return "V";}
    elsif ($tag =~ /VBG/) { return "VBG";}
    elsif ($tag =~ /VBN/) { return "VBN";}
    elsif ($tag =~ /VBP/) { return "V";}
    elsif ($tag =~ /VBZ/) { return "V";}
    elsif ($tag =~ /VB/) { return "V";}
    elsif ($tag =~ /WDT/) { return "D";}
    elsif ($tag =~ /WP\$/) { return "P";}
    elsif ($tag =~ /WP/) { return "P";}
    elsif ($tag =~ /WRB/) { return "R";}
    elsif ($tag =~ /\`\`/) { return "SCM";}
    elsif ($tag =~ /\$/) { return "N";}
    elsif ($tag =~ /RB/) { return "R";}
    elsif ($tag =~ /RP/) { return "IN";}
    elsif ($tag =~ /DT/) { return "D";}
    else {die "Bad Penn Tag: $_\n";};
};

sub link_segs {
# the calling routine should be only interested in %bind, and
# possibly @staken and @ttaken
    my($sseg, $tseg, $assocptr, $minassoc) = @_;
    my(%con1, %con2);
    my($sword, $tword);
    my($adding, $i, $j);
    my(%bestlink1, %bestlink2);
    my($sind, $tind, $maxdep);

    for($i = 0; $i < @$sseg; $i++) {
	$sword = $$sseg[$i];
	for($j = 0; $j < @$tseg; $j++) {
	    $tword = $$tseg[$j];
	    if (exists $$assocptr{$sword}{$tword}) {
		$con1{$i}{$j} = $con2{$j}{$i} = $$assocptr{$sword}{$tword};
	    };
	};
    };

    %bind = {};
    @staken = @ttaken = ();

#   $slope = @$tseg / @$sseg;
    do {
	$adding = $FALSE;
	%bestlink1 = %bestlink2 = {};

	foreach $sind ( keys %con1) {
	    if ($staken[$sind]) { next; };
            $maxdep = $minassoc;
	    foreach $tind ( keys %{$con1{$sind}}) {
		if ($ttaken[$tind]) { next; };
#		if ($tind - $sind * $slope > 2) { next; };
		if ($maxdep < $con1{$sind}{$tind}) {
		    $maxdep = $con1{$sind}{$tind};
		    $bestlink1{$sind} = {};
		    $bestlink1{$sind}{$tind} = $TRUE;
		} elsif ($maxdep == $con1{$sind}{$tind}) {
		    $bestlink1{$sind}{$tind} = $TRUE;
		};
	    };
	};
	
	foreach $tind ( keys %con2) {
	    if ($ttaken[$tind]) { next; };
            $maxdep = $minassoc;
	    foreach $sind ( keys %{$con2{$tind}}) {
		if ($staken[$sind]) { next; };
#		if ($tind - $sind * $slope > 2) { next; };
		if ($maxdep < $con2{$tind}{$sind}) {
		    $maxdep = $con2{$tind}{$sind};
		    $bestlink2{$tind} = {};
		    $bestlink2{$tind}{$sind} = $TRUE;
		} elsif ($maxdep == $con2{$tind}{$sind}) {
		    $bestlink2{$tind}{$sind} = $TRUE;
		};
	    };
	};
	

	foreach $sind ( keys %bestlink1) { 
	    foreach $tind ( keys %{$bestlink1{$sind}}) {
		if (defined $bestlink2{$tind}{$sind}) {
		    $bind{$sind}{$tind} = $TRUE;
		    $staken[$sind]++;
		    $ttaken[$tind]++;
		    # print STDERR "$$sseg[$sind] $$tseg[$tind]\n";
		
		    $adding = $TRUE;
		};
	    };
	};
    } while ($adding);
};


sub resolve_links {
# the calling routine should be only interested in %bind, and
# possibly @staken and @ttaken
    my($con1ptr, $con2ptr, $minassoc) = @_;
    my($adding, $i, $j);
    my(%bestlink1, %bestlink2);
    my($sind, $tind, $maxdep);

    %bind = {};
    @staken = @ttaken = ();

    do {
	$adding = $FALSE;
	%bestlink1 = %bestlink2 = {};

	foreach $sind ( keys %$con1ptr) {
	    if ($staken[$sind]) { next; };
            $maxdep = $minassoc;
	    foreach $tind ( keys %{$$con1ptr{$sind}}) {
		if ($ttaken[$tind]) { next; };
		if ($maxdep < $$con1ptr{$sind}{$tind}) {
		    $maxdep = $$con1ptr{$sind}{$tind};
		    $bestlink1{$sind} = {};
		    $bestlink1{$sind}{$tind} = $TRUE;
		} elsif ($maxdep == $$con1ptr{$sind}{$tind}) {
		    $bestlink1{$sind}{$tind} = $TRUE;
		};
	    };
	};
	
	foreach $tind ( keys %$con2ptr) {
	    if ($ttaken[$tind]) { next; };
            $maxdep = $minassoc;
	    foreach $sind ( keys %{$$con2ptr{$tind}}) {
		if ($staken[$sind]) { next; };
		if ($maxdep < $$con2ptr{$tind}{$sind}) {
		    $maxdep = $$con2ptr{$tind}{$sind};
		    $bestlink2{$tind} = {};
		    $bestlink2{$tind}{$sind} = $TRUE;
		} elsif ($maxdep == $$con2ptr{$tind}{$sind}) {
		    $bestlink2{$tind}{$sind} = $TRUE;
		};
	    };
	};
	

	foreach $sind ( keys %bestlink1) { 
	    foreach $tind ( keys %{$bestlink1{$sind}}) {
		if (defined $bestlink2{$tind}{$sind}) {
		    $bind{$sind}{$tind} = $TRUE;
		    $staken[$sind]++;
		    $ttaken[$tind]++;
		    $adding = $TRUE;
		};
	    };
	};
    } while ($adding);
};




return 1;
