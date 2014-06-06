#!/usr/bin/perl

### mixlangs.pl tolang.lng fromlang.lng factor

### Perl script to mix words from 'fromlang' to 'tolang'. 
### Juha Vesanto 010897

## init

# input arguments

$input_args = join(' ',@ARGV);
$tolang = shift(@ARGV);
$fromlang = shift(@ARGV);
$mixfactor = shift(@ARGV);

# equivalence classes

$eq1{'a'} = "a:ae:ai";
$eq1{'b'} = "b:p:bh";
$eq1{'c'} = "c:g:k:q";
$eq1{'d'} = "d:t";
$eq1{'e'} = "e:ei:ea";
$eq1{'f'} = "f:v:fh";
$eq1{'g'} = "g:k:c:q:gh";
$eq1{'h'} = "h:rh";
$eq1{'i'} = "i:ie";
$eq1{'j'} = "j:z:dh:ch";
$eq1{'k'} = "k:c:q:g:x";
$eq1{'l'} = "l:lh";
$eq1{'m'} = "m:mn";
$eq1{'n'} = "n:nh";
$eq1{'o'} = "o:ou";
$eq1{'p'} = "p:b:ph";
$eq1{'q'} = "q:c:k:g";
$eq1{'r'} = "r";
$eq1{'s'} = "s:z:sh:sch";
$eq1{'t'} = "t:d:th";
$eq1{'u'} = "u:y";
$eq1{'v'} = "v:f:w";
$eq1{'w'} = "w:v:wh";
$eq1{'x'} = "x:ks";
$eq1{'y'} = "y:u";
$eq1{'z'} = "z:s:j";

# search unique sequences from the equivalence classes

@eqs = (keys(%eq1),split(':',join(':',values(%eq1))));
@eqs = sort(@eqs);
for ($i=0; $i<$#eqs; ) {
    if ($eqs[$i] eq $eqs[$i+1]) {
	@eqs = (@eqs[0 .. $i,$i+2 .. $#eqs]);
    } else { $i++; }
}

## read

# words from language1

open (WORDS,"$tolang") || die "Cannot open $tolang\n";
@lines = <WORDS>; 
chop(@lines); 
close(WORDS);
foreach $l (@lines) {
    if ($l=~/^#/) { 
	push(@comments1,$l); 
    }
    $i = index($l,';');
    $word = substr($l,0,$i); 
    $meaning = substr($l,$i+1);
    if ($dict1{$meaning}) {
	$dict1{$meaning} .= ", $word";
    } else { $dict1{$meaning} = $word; }
}

# words from language2

open (WORDS,"$fromlang") || die "Cannot open $fromlang\n";
@lines = <WORDS>; 
chop(@lines); 
close(WORDS);
foreach $l (@lines) {
    if ($l=~/^#/) { 
	next; 
    }
    $i = index($l,';');
    $word = substr($l,0,$i); 
    $meaning = substr($l,$i+1);
    if ($dict2{$word}) {
	$dict2{$word} .= ", $meaning";
    } else { $dict2{$word} = $meaning; }
}

## analyse

$lineout=""; 
foreach $w (values(%dict1)) { 
    $w =~ tr/,//;
    $lineout.=$w.' '; 
    if (length($lineout)>60) {
	push(@wordlines,$lineout); $lineout="";
    }
}
push(@wordlines,$lineout);

# frequencies of each equivalence key

$d = join('',@wordlines);
study($d);
foreach $e (@eqs) { 
    $freq{$e} = 0; 
    $i=0; while ($d =~ m/$e/g) { $i++; }
    $freq{$e} = $i;
    #print STDERR "$e : $i\n";
}

# characters following each character doublet

foreach (@wordlines) {
    @chars = split('', $_);
    for ($c = 0; $c < $#chars-2; $c++) {
	$doublet = $chars[$c].$chars[$c+1];
	if ($chars[$c-1] =~ /[^\S]/ || !$c) { push(@inits, $doublet); }
	$array2{$doublet} .= $chars[$c+2];
    }
    /(\S\s)$/;
    $array2{$1} .= $chars[0];
    $rewind = ' '.$chars[0];
    $array2{$rewind} .= $chars[1];
}

# characters in the middle of each character triplet

foreach (@wordlines) {
    @chars = split('', $_);
    for ($c = 0; $c < $#chars-2; $c++) {
	$doublet = $chars[$c].$chars[$c+2];
	$array3{$doublet} .= $chars[$c+1];
    }
}

## convert

$n = $mixfactor*scalar(%dict1);
@words2 = keys(%dict2);
for (1 .. $n) {
    $newword = ''; 
    $oldword = $words2[rand $#words2];
    
    # character conversion

    @chars = split('',$oldword);
    foreach $c (@chars) {
	if ($eq1{$c}) {
	    @r = split(':',$eq1{$c}); 
	    $sum = 0; @f = ();
	    foreach $i (@r) { push(@f,$freq{$i}); $sum += $freq{$i}; }
	    $j = rand $sum; 
	    $i = 0; while ($j>=0 && $i<$#r) { $j -= $f[$i]; $i++; }
	    #print STDERR "Replacing $c with ",$r[$i-1],"\n";
	    $c = $r[$i-1]; 
	}
	$newword .= $c;
    } 

    # utilize the doublet and triplet information
       
    @chars = split('',$newword);
    $chars[$#chars+1] = ' ';
    $nw = ''; $c0=' '; $c1 = $chars[0]; $c2 = $chars[1]; $i=1;
    $changes=0;
    while ($c1 ne " " ) {
	if ($array3{$c0.$c2} =~ /$c1/) { 
	    $nw = $nw.$c1; 
            $c0=$c1; $c1=$c2; $i++; $c2=$chars[$i];
	} elsif ($array3{$c0.$c1}) {
	    $a=$array3{$c0.$c1}; $c=$a[rand $#a]; $nw.=$c; $c0=$c; 
	    $changes++;
	} elsif ($array2{$c0.$c2}) {
	    $c1=$c2; $i++; $c2=$chars[$i];
	    $changes++;
	} else { 
	    $nw.=$c1; $c0=$c1; $c1=$c2; $i++; $c2=$chars[$i]; 
	}
    }

    # word endings (doesn't work very well)
 
    $c0=substr($nw,-2,1); $c1=substr($nw,-1,1);
    while ($c1 ne ' ') {
	if (index($array2{$c0.$c1},' ')>=0) {
	    $c1 = ' '; 
	} elsif ($array2{$c0.$c1}) {
	    $a=$array2{$c0.$c1}; $c=$a[rand $#a]; $nw.=$c; $c0=$c1; $c1=$c; 
	} else {
	    $c1 = ' ';
	}
    }

    $meaning = $dict2{$oldword};
    $dict1{$meaning} = "$nw";
    #print STDERR "$oldword ($meaning) -> $nw\n";
}

## output

@lines = @comments1;
push(@lines,"# mixlangs.pl $input_args");
@meanings = sort(keys(%dict1));
foreach $m (@meanings) {
    push(@lines,"$dict1{$m};$m");
}
print join("\n",@lines)."\n";

# that's it!