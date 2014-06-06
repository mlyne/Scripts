
my ($last_test,$loaded);

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';

BEGIN { $last_test = 29; $| = 1; print "1..$last_test\n"; }
END   { print "not ok 1  Can't load Algorithm::Cluster\n" unless $loaded; }

use Algorithm::Cluster;
no  warnings 'Algorithm::Cluster';

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub test;  # Predeclare the test function (defined below)

my $tcounter = 1;
my $want     = '';


#------------------------------------------------------
# Data for Tests
# 

#----------
# dataset 1
#
my $matrix   =  [
        [],
        [ 3.4],
        [ 4.3, 10.1],
        [ 3.7, 11.5,  1.1],
        [ 1.7,  4.1,  3.4,  3.4],
        [10.1, 20.5,  2.5,  2.7,  9.8],
        [ 2.5,  3.7,  3.1,  3.6,  1.1, 10.1],
        [ 3.4,  2.2,  8.8,  8.7,  3.3, 16.6,  2.7],
        [ 2.1,  7.7,  2.7,  1.9,  1.8,  5.7,  3.4,  5.2],
        [ 1.6,  1.8,  9.2,  8.7,  3.4, 16.8,  4.2,  1.3,  5.0],
        [ 2.7,  3.7,  5.5,  5.5,  1.9, 11.5,  2.0,  1.7,  2.1,  3.1],
        [10.0, 19.3,  2.2,  3.7,  9.1,  1.2,  9.3, 15.7,  6.3, 16.0, 11.5]
];

#------------------------------------------------------
# Tests
# 

my ($clusters, $error, $found);

#------------------------------------------------------
# Test with repeated runs of the k-medoids algorithm
# 

my %params1 = (
        nclusters =>         4,
        distances =>   $matrix,
        npass     =>       100,
);
                                                                                
($clusters, $error, $found) = Algorithm::Cluster::kmedoids(%params1);

#----------
# Make sure that the length of @clusters matches the length of @data
$want = scalar @$matrix;       test q( scalar @$clusters );

#----------
# Test the cluster assignments
$want = '9';       test q( $clusters->[ 0]);
$want = '9';       test q( $clusters->[ 1]);
$want = '2';       test q( $clusters->[ 2]);
$want = '2';       test q( $clusters->[ 3]);
$want = '4';       test q( $clusters->[ 4]);
$want = '5';       test q( $clusters->[ 5]);
$want = '4';       test q( $clusters->[ 6]);
$want = '9';       test q( $clusters->[ 7]);
$want = '4';       test q( $clusters->[ 8]);
$want = '9';       test q( $clusters->[ 9]);
$want = '4';       test q( $clusters->[10]);
$want = '5';       test q( $clusters->[11]);

# Test the within-cluster sum of errors
$want = ' 11.800';       test q( sprintf "%7.3f", $error);


#------------------------------------------------------
# Test the k-medoids algorithm with a specified initial clustering
# 

$initialid = [0,0,1,1,1,2,2,2,3,3,3,3];

my %params2 = (
        nclusters =>         4,
        distances =>   $matrix,
        npass     =>         1,
        initialid => $initialid,
);
                                                                                
($clusters, $error, $found) = Algorithm::Cluster::kmedoids(%params2);

#----------
# Make sure that the length of @clusters matches the length of @data
$want = scalar @$matrix;       test q( scalar @$clusters );

#----------
# Test the cluster assignments
$want = '9';       test q( $clusters->[ 0]);
$want = '9';       test q( $clusters->[ 1]);
$want = '2';       test q( $clusters->[ 2]);
$want = '2';       test q( $clusters->[ 3]);
$want = '4';       test q( $clusters->[ 4]);
$want = '2';       test q( $clusters->[ 5]);
$want = '6';       test q( $clusters->[ 6]);
$want = '9';       test q( $clusters->[ 7]);
$want = '4';       test q( $clusters->[ 8]);
$want = '9';       test q( $clusters->[ 9]);
$want = '4';       test q( $clusters->[10]);
$want = '2';       test q( $clusters->[11]);

# Test the within-cluster sum of errors
$want = ' 14.200';       test q( sprintf "%7.3f", $error);


#------------------------------------------------------
# Test function
# 
sub test {
	$tcounter++;

	my $string = shift;
	my $ret = eval $string;
	$ret = 'undef' if not defined $ret;

	if("$ret" =~ /^$want$/sm) {

		print "ok $tcounter\n";

	} else {
		print "not ok $tcounter\n",
		"   -- '$string' returned '$ret'\n", 
		"   -- expected =~ /$want/\n"
	}
}

__END__



