$FALSE = 0;
$TRUE = 1;
$INFINITY = 9999999999;
$TINY = 0.0000000001;


sub min {
    my($x, $y) = @_;
    if ($x < $y) {
	return $x;
    } else {
	return $y;
    };
};


sub minratio {
# returns smaller of x/y or y/x
    my($x, $y) = @_;
    if ($x < $y) {
	return $x / $y;
    } else {
	return $y / $x;
    };
};


sub max {
    my($x, $y) = @_;
    if ($x > $y) {
	return $x;
    } else {
	return $y;
    };
};


sub round {
# rounds numbers to the specified precision
    my($prec,$orig) = @_;
    my($sign) = $orig <=> 0;
    return int($orig / $prec + .5 * $sign) * $prec;
};


sub genhash {
# returns pointer to new empty hash
    
    my(%newhash) = ();

    return \%newhash;
};

sub maxar {
# returns @$arptr index with highest value, 
# out of those listed in @$choice
    ($arptr, $choice) = @_;

    my($m, $i) = (0, 0);
    while ($i <= $#$choice) {
	if ($$arptr[$$choice[$i]] > $$arptr[$$choice[$m]]) {
	    $m = $i;
	};
	$i++;
    };
    return $$choice[$m];
};


sub maxkey {
# returns hash key with highest value
# ties broken randomly
# $hptr is a pointer to a hash
# $min is the minimum possible value
# the $min parameter is optional and defaults to zero

    my($hptr, $min) = @_;
    my($key, $value, $maxkey);

    while (($key, $value) = each %$hptr) {
        if ($min < $value) {
            $min = $value;
            $maxkey = $key;
        };
    };
    
    return $maxkey;

};

sub regress {
    my($xptr, $yptr) = @_;	# pointers to arrays

    my($ind, $x, $y, $sumx, $sumy, $sumxy, $sumsqx);
    my($count, $ex, $ey, $slope, $intercept);

    foreach $ind (0 .. $#$xptr) {
	$x = $$xptr[$ind];
	$y = $$yptr[$ind];
	$sumx += $x;
	$sumy += $y;
	$sumxy += $x * $y;
	$sumsqx += $x * $x;
	$count++;
    };

    $ex = $sumx / $count;
    $ey = $sumy / $count;

    $slope = ($sumxy - $count * $ex * $ey) / ($sumsqx - $count * $ex ** 2);
    $intercept = $ey - $slope * $ex;

    # first number is slope; second is y-intercept
    
    return ($slope, $intercept);

};


sub minar {
# returns @$arptr index with lowest value, 
# out of those listed in @$choice
    ($arptr, $choice) = @_;

    my($m, $i) = (0,0);
    while ($i <= $#$choice) {
	if ($$arptr[$$choice[$i]] < $$arptr[$$choice[$m]]) {
	    $m = $i;
	};
	$i++;
    };
    return $$choice[$m];
};

sub maxar_string {
# returns @$arptr index with highest value, 
# out of those listed in @$choice
    ($arptr, $choice) = @_;

    my($m, $i) = (0, 0);
    while ($i <= $#$choice) {
	if ($$arptr[$$choice[$i]] gt $$arptr[$$choice[$m]]) {
	    $m = $i;
	};
	$i++;
    };
    return $$choice[$m];
};


sub minar_string {
# returns @$arptr index with lowest value, 
# out of those listed in @$choice
    ($arptr, $choice) = @_;

    my($m, $i) = (0,0);
    while ($i <= $#$choice) {
	if ($$arptr[$$choice[$i]] lt $$arptr[$$choice[$m]]) {
	    $m = $i;
	};
	$i++;
    };
    return $$choice[$m];
};

sub eqar {
# boolean string array "equals"
    my($ptr1, $ptr2) = @_;
    my($i);

    if ($#{$ptr1} != $#{$ptr2}) {
	return $FALSE;
    };
    for($i = 0; $i < @$ptr1; $i++) {
	if ($$ptr1[$i] ne $$ptr2[$i]) {
	    return $FALSE;
	};
    };

    return $TRUE;
};


sub eqar_numeric {
# boolean numeric array "equals"
    my($ptr1, $ptr2) = @_;
    my($i);

    if ($#{$ptr1} != $#{$ptr2}) {
	return $FALSE;
    };
    for($i = 0; $i < @$ptr1; $i++) {
	if ($$ptr1[$i] != $$ptr2[$i]) {
	    return $FALSE;
	};
    };

    return $TRUE;
};


sub eqhash_numeric {
# boolean numeric hash "equals"
# works with numeric hashes of arbitrary depth
    my($ptr1, $ptr2) = @_;

    if (not &eqar_numeric([sort bynumber keys %$ptr1], 
			  [sort bynumber keys %$ptr2])) {
	return $FALSE;
    };

    my($key1, $value1);
    while (($key1, $value1) = each %$ptr1) {
	if (exists $$ptr2{$key1}) {
	    if (ref($value1) eq "HASH" 
		and (ref($$ptr2{$key1}) eq "HASH")
		and (not &eqhash_numeric($value1, $$ptr2{$key1}))) {
		return $FALSE;
	    } elsif (! ref($value1) and ! ref($$ptr2{$key1})
		     and ($value1 != $$ptr2{$key1})) {
		return $FALSE;
	    };
	} else {
	    return $FALSE;
	};
    };

    return $TRUE;
};


sub gtar_numeric {
# boolean numeric array "greather than"
    my($ptr1, $ptr2) = @_;
    my($i, $maxind);

    $maxind = &min($#{$ptr1}, $#{$ptr2});
    for($i = 0; $i <= $maxind; $i++) {
	if ($$ptr1[$i] < $$ptr2[$i]) {
	    return $FALSE;
	};
    };
    if ($#{$ptr1} <= $#{$ptr2}) {
	return $FALSE;
    };

    return $TRUE;
};


sub bynumar { 
# sort subroutine: numeric arrays
    my($i, $uc, $lc);

    if ($#{$a} <= $#{$b}) {
	$lc = $a;
	$uc = $b;
    } else {
	$uc = $a;
	$lc = $b;
    } 
    for($i = 0; $i < @$lc; $i++) {
	if ($$a[$i] < $$b[$i]) {
	    return -1;
	} elsif ($$a[$i] > $$b[$i]) {
	    return 1;
	};
    };
    
    if ($#{$a} < $#{$b}) {
	return -1;
    } else {
	return 0;
    };
};

sub arcopy {
# returns a copy of the array
# used for passing recursive arrays by value
    my($arptr) = shift;

    my(@newar);

    foreach $el (@$arptr) {
	if (not ref($el)) {
	    push(@newar, $el);
	} elsif (ref($el) eq "ARRAY") {
	    push(@newar, &arcopy($el));
	} else {
	    die "Element in recursive array is a non-array reference!\n";
	};
    };

    return [@newar];
};


sub insar_numeric_uniq {
# inserts numeric array into sorted list of arrays
# if array already exists, only one copy is kept
# returns pointer to new list of arrays, and index of insertion
# if not unique, then index of insertion = -1

    my($ararptr, $iarptr) = @_;
    my($i);

    for($i = 0; $i <= $#{$ararptr}; $i++) {
	if (&eqar_numeric($$ararptr[$i], $iarptr)) {
	    return ($ararptr, -1); # no insertion
	} elsif (&gtar_numeric($$ararptr[$i], $iarptr)) {
	    splice(@$ararptr, $i, $iarptr);
	    return ($ararptr, $i);
	};
    };

    # greatest so far
    push(@$ararptr, $iarptr);
    return ($ararptr, $i+1);
};


sub rnd {
    my($min, $max) = @_;
    $range = $max - $min + 1;
    return int(rand() * $range + $min);
};


sub byvalue { $val{$a} <=> $val{$b} };
sub bynumber { $a <=> $b };


sub isnumber {
    my($x) = @_;
    $z = $x;
    return ($z + 0 != 0 || $x eq "0" || $x eq "0.0");
};


sub Log {
    my($p) = @_;

    if ($p == 0)
    {-999999;}
    else
    {log($p)};
}

sub string_lcs {
# length of longest common subsequence of two strings
# uses dynamic programming
    my($str1, $str2) = @_;
    my(@m, $i, $j);
    
    my(@c1) = split('', $str1);
    my(@c2) = split('', $str2);

    if ($c1[0] eq $c2[0]) {
	$m[0][0] = 1;
    } else {
	$m[0][0] = 0;
    };

    for($i = 1; $i <= $#c1; $i++) {
        if ($c1[$i] eq $c2[0]) {
          $m[$i][0] = 1;
        } else {
          $m[$i][0] = $m[$i-1][0];
        };
    };

    for($j = 1; $j <= $#c2; $j++) {
        if ($c2[$j] eq $c1[0]) {
          $m[0][$j] = 1;
        } else {
          $m[0][$j] = $m[0][$j-1];
        };
    };

    for($i = 1; $i <= $#c1; $i++) {
	for($j = 1; $j <= $#c2; $j++) {
	    if ($c1[$i] eq $c2[$j]) {
		$m[$i][$j] = $m[$i-1][$j-1] + 1;
	    } else {
		$m[$i][$j] = &max($m[$i-1][$j], $m[$i][$j-1]);
	    };
	};
    };

    return $m[$#c1][$#c2];
};


sub bsearch {
# returns index of highest element in array that
#         is smaller than target
# array should be sorted in increasing order
# N.B.:  if whole array is to be searched, then
#        the first $min parameter should = -1.
#        This way, if $$arptr[0] > $target, the
#        search can return -1;
# Also, if $#$arptr < 0, returns -1;
# this version does numeric comparisons

    my( $target, $min, $max, $arptr) = @_;
    if ($#$arptr < 0) {return -1};
    my( $shot, $comp);

    if ($min >= $max - 1) {
	$comp = $$arptr[$max] <=> $target;
	if ($comp < 0) {
	    return $max;
	} else {
	    return $min;
	};
    };

    $shot = int(($max + $min) * .5);
    $comp = $$arptr[$shot] <=> $target;
    if ($comp == 0) {
	return $shot;
    } elsif ( $comp < 0 ) {
	return &bsearch( $target, $shot, $max, $arptr);
    } else {
	return &bsearch( $target, $min, $shot, $arptr);
    };
};

sub nupdsort {
# numerical push-down sort, with uniq
    my($stackptr, $inputptr) = @_;
    my($ss);

    foreach $ss (@$inputptr) {
	$outind = $#$stackptr;
	while ($outind >=0 and
	       ($$inputptr[$ss] < $$stackptr[$outind])) {
	    $outind--;
	};
	if ($$inputptr[$ss] == $$stackptr[$outind]) {
	    next;
	};
	$outind++;
	splice(@$stackptr, $outind, 0, $$inputptr[$ss]);
    };

    return $stackptr;
};

sub usort {
# string sort with unique
    my(@sorted) = sort @_;
    my($i);

    for($i = $#sorted; $i > 0; $i--) {
	if ($sorted[$i] eq $sorted[$i - 1]) {
	    splice(@sorted, $i, 1);
	};
    };

    return \@sorted;
};

sub dump_hash {
    my($hashptr) = shift;
    my($key, $value);

    while (($key,$value) = each %$hashptr) {
	print "$key $value\n";
    };
};

sub dump_hash_to_handle {
    my($handle, $hashptr) = @_;
    my($key, $value);

    while (($key,$value) = each %$hashptr) {
	print $handle "$key $value\n";
    };
};

sub condent {
# conditional entropy of a hash
# "<NULL>::NU" key has special status
    my($dpsize, $hashptr, $sfrqptr) = @_;
    # dpsize is the size of the dotproduct

    my($currfrq, $lfrq, $ent, $source, $targ, $nulls);
    my(%sent);

    foreach $source (keys %$hashptr) {
	$currfrq = $$sfrqptr{$source};
	$ent = 0;
	while (($targ, $lfrq) = each %{$$hashptr{$source}}) {
	    $ent += &ent( $lfrq / $currfrq);
	};
	
	if (exists $$hashptr{$source}{"<NULL>::NU"}) {
	    $nulls = $$hashptr{$source}{"<NULL>::NU"};
	    $ent += $nulls * &ent( 1 / $currfrq) 
		- &ent($nulls / $currfrq);
	};
	
	$sent{$source} = $ent * $currfrq / $dpsize;
    };

    return \%sent;
};


sub jointent {
# joint entropy of a hash
# "<NULL>::NU" key has special status
    my($dpsize, $hashptr, $sfrqptr) = @_;
    # dpsize is the size of the dotproduct

    my($lfrq, $ent, $source, $targ, $nulls);
    my(%sent);

    foreach $source (keys %$hashptr) {
	if ($source eq "<NULL>::NU") {
	    $sent{$source} = $$sfrqptr{$source} * &ent(1 / $dpsize);
	    next;
	};
	$ent = 0;
	while (($targ, $lfrq) = each %{$$hashptr{$source}}) {
	    $ent += &ent( $lfrq / $dpsize);
	};
	
	if (exists $$hashptr{$source}{"<NULL>::NU"}) {
	    $nulls = $$hashptr{$source}{"<NULL>::NU"};
	    $ent += $nulls * &ent( 1 / $dpsize) 
		- &ent($nulls / $dpsize);
	};
	
	$sent{$source} = $ent;
    };

    return \%sent;
};


sub modmi {
# mutual information of a two distributions
    my($dpsize, $jfrqptr, $sfrqptr, $tfrqptr) = @_;
    # dpsize is the size of the dotproduct

    my($modmi, $lfrq, $source, $targ);

    foreach $source (keys %$sfrqptr) {
	while (($targ, $lfrq) = each %{$$jfrqptr{$source}}) {
	    $modmi += &mi( $lfrq, $$sfrqptr{$source}, 
			  $$tfrqptr{$targ}, $dpsize);
	};
    };

    return $modmi;
};

sub modmi_nonulls {
# mutual information of a translation model
# "<NULL>::NU" key has special status
    my($dpsize, $jfrqptr, $sfrqptr, $tfrqptr) = @_;
    # dpsize is the size of the dotproduct

    my($lfrq, $sfrq, $mi, $source, $targ, $nulls);
    my(%mi);

    foreach $source (keys %$jfrqptr) {
	$sfrq = $$sfrqptr{$source};
	if ($source eq "<NULL>::NU") {
	    $mi{$source} = 0;
	    next;
	};
	$mi = 0;
	while (($targ, $lfrq) = each %{$$jfrqptr{$source}}) {
	    $mi += &mi( $lfrq, $sfrq, $$tfrqptr{$targ}, $dpsize);
	};
	
	if (exists $$jfrqptr{$source}{"<NULL>::NU"}) {
	    $nulls = $$jfrqptr{$source}{"<NULL>::NU"};
	    $mi -= &mi( $nulls, $sfrq, $$tfrqptr{"<NULL>::NU"}, $dpsize);
	};
	
	$modmi += $mi;
    };

    return $modmi;
};


sub mutinf {
# mutual information of a hash
# "<NULL>::NU" key has special status
    my($dpsize, $jfrqptr, $sfrqptr, $tfrqptr) = @_;
    # dpsize is the size of the dotproduct

    my($lfrq, $sfrq, $mi, $source, $targ, $nulls);
    my(%mi);

    foreach $source (keys %$jfrqptr) {
	$sfrq = $$sfrqptr{$source};
	if ($source eq "<NULL>::NU") {
	    $mi{$source} = 0;
	    next;
	};
	$mi = 0;
	while (($targ, $lfrq) = each %{$$jfrqptr{$source}}) {
	    $mi += &mi( $lfrq, $sfrq, $$tfrqptr{$targ}, $dpsize);
	};
	
	if (exists $$jfrqptr{$source}{"<NULL>::NU"}) {
	    $nulls = $$jfrqptr{$source}{"<NULL>::NU"};
	    $mi -= &mi( $nulls, $sfrq, $$tfrqptr{"<NULL>::NU"}, $dpsize);
	};
	
	$mi{$source} = $mi;
    };

    return \%mi;
};


sub predval {
# predictive value of a hash
# "<NULL>::NU" key has special status
    my($dpsize, $jfrqptr, $sfrqptr, $tfrqptr) = @_;
    # dpsize is the size of the dotproduct

    my($lfrq, $sfrq, $pv, $source, $targ);
    my($mlfrq, $mltarg);
    my(%pv);

    foreach $source (keys %$jfrqptr) {
	$mlfrq = 0;
	while (($targ, $lfrq) = each %{$$jfrqptr{$source}}) {
            if ($mlfrq < $lfrq) {
                $mlfrq = $lfrq;
                $mltarg = $targ;
            };
	};

	if ($mltarg eq "<NULL>::NU") {
	    $pv{$source} = 0;
	} else {
	    $pv{$source} = &mi( $mlfrq, $$sfrqptr{$source}, $$tfrqptr{$mltarg}, $dpsize);
	};
    };

    return \%pv;
};


sub jointent_with_modent {
# joint entropy of a hash
# "<NULL>::NU" key has special status
    my($dpsize, $jfrqptr, $sfrqptr) = @_;
    # dpsize is the size of the dotproduct

    my($lfrq, $ent, $source, $targ, $nulls, $modelent);
    my(%sent);

    foreach $source (keys %$jfrqptr) {
	if ($source eq "<NULL>::NU") {
	    $sent{$source} = $$sfrqptr{$source} * &ent(1 / $dpsize);
	    $modelent += $sent{$source};
	    next;
	};
	$ent = 0;
	while (($targ, $lfrq) = each %{$$jfrqptr{$source}}) {
	    $ent += &ent( $lfrq / $dpsize);
	};
	
	if (exists $$jfrqptr{$source}{"<NULL>::NU"}) {
	    $nulls = $$jfrqptr{$source}{"<NULL>::NU"};
	    $ent += $nulls * &ent( 1 / $dpsize) 
		- &ent($nulls / $dpsize);
	};
	
	$sent{$source} = $ent;
	$modelent += $sent{$source};
    };

    return (\%sent, $modelent);
};


sub jointent2 {
# computes the same thing as &jointent by summing up conditional and 
# marginal separately
# "<NULL>::NU" key has special status
    my($dpsize, $jfrqptr, $sfrqptr) = @_;
    # dpsize is the size of the dotproduct

    my($currfrq, $lfrq, $ent, $source, $targ, $nulls);
    my(%sent);

    foreach $source (keys %$jfrqptr) {
	$currfrq = $$sfrqptr{$source};
	$ent = 0;
	while (($targ, $lfrq) = each %{$$jfrqptr{$source}}) {
	    $ent += &ent( $lfrq / $currfrq);
	};
	
	if (exists $$jfrqptr{$source}{"<NULL>::NU"}) {
	    $nulls = $$jfrqptr{$source}{"<NULL>::NU"};
	    $ent += $nulls * &ent( 1 / $currfrq) 
		- &ent($nulls / $currfrq);
	};
	
	$sent{$source} = $ent * $currfrq / $dpsize
	    + &ent($currfrq / $dpsize);
    };

    return \%sent;
};


sub ent {
    my($prob) = shift;

    if ($prob == 0) {
        return 0;
    } elsif ($prob < 0 or $prob > 1) {
        die "ERROR in $0: Not a probability value: $prob ($currsrc, $cont, $targ)\n";
    };

    return - $prob * log($prob);
};

sub mi {
    my($numer, $den1, $den2, $events) = @_;

    if ($numer == 0) {
	return 0;
    };

    if ($numer < 0 or $numer > $events) {
	die "MI: Numerator = $numer ($currsrc, $cont, $targ)\n";
    };

    if ($den1 <= 0 or $den1 > $events) {
	die "&mi: Denominator 1 = $den1 ($currsrc, $cont, $targ)\n";
    };

    if ($den2 <= 0 or $den2 > $events) {
	die "&mi: Denominator 2 = $den2 ($currsrc, $cont, $targ)\n";
    };

    return $numer / $events * log($numer / $den1 * $events / $den2 );
};


sub rel_ent {
    my($numer, $denom) = @_;

    if ($numer == $denom or $numer == 0) {
	return 0;
    };

    return $numer * log( $numer / $denom);
};


sub cross_ent {
    my($numer, $denom) = @_;

    return - $numer * log( $denom);
};


sub log_exp_prob {
# log-probability of alpha given exponential parameter beta
    my($alpha, $beta) = @_;

    return log($beta) - $beta * $alpha;
};

return 1;
