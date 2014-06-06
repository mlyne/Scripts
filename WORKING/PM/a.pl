use warnings;
no warnings 'uninitialized';
use XML::Twig;
use Data::Dumper;

# -- Set Common Variables --- #
my $tg="Type";            # Starting Tag of XML file
my $file="NWTYPE_longer.xml";    # XML File Location

# Set XML Tags Name
my @tags=(
	"TypeID","Manufacturer","Model","TypeName","DriveType","Wheelbase",
	"Tyres","FuelTank","SeatNumberTotal","Width","Length","Height","CurbWeight",
	"TotalWeight","TransmissionType","GearNumber","DoorNumber","MotorVolCm3","PowerKW",
	"PowerHP","FuelType","Acceleration","MaxSpeed","ExistenceStart","Price","Currency",
	"PriceType","TorqueNM","TrunkVol","EUEconomy","Material"
	);
my $tags;

# --- Parse The XML File --- #
my $parser=XML::Twig->new()->safe_parsefile($file);
die($@) if $@;
#my $is_there;
#foreach($parser->findnodes("//TypeID")){
#	#print $_->name."\n";
#	if($_->is_elt && $_->string_value){$is_there=1; last;}
#	}
#do{
#	print qq{Doesn't make sense to continue. Not TypeID tag or value found in '$file'\n};
#	exit 1;
#	} unless $is_there==1;



my @nodes=$parser->findnodes("/TypeFile/Type");
scalar @nodes > 0 or do{
	print qq{No '/TypeFile/Type' structure found. Can't continue\n};
	exit 1;
	};

foreach my $p (@nodes){
	my $el=$p->has_children($tags[0]);
	($el && $el->string_value) or do{
		print STDERR "Not found the required $tags[0]. Skipping this node...\n";
		next;
		};
	foreach my $n (sort @tags){
		foreach my $sn ($p->findnodes($n)){
			print $sn->name."->".$sn->string_value."\n" if $sn->is_elt;
			}
		}
	}
