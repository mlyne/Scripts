#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Bio::EnsEMBL::LookUp;

use Bio::EnsEMBL::Registry;

my $registry = 'Bio::EnsEMBL::Registry';

my $dbname = 'bacteria_18_collection_core_20';

$registry->load_registry_from_db(
  -host => 'mysql.ebi.ac.uk',
  -port => 4157,
  -user => 'anonymous'
  #-verbose => '1'
);

# $registry->load_registry_from_db(
#    -host => 'useastdb.ensembl.org', # alternatively 'useastdb.ensembl.org'
#    -user => 'anonymous',
# );

#my @db_adaptors = @{ $registry->get_all_DBAdaptors() };

# foreach my $db_adaptor (@db_adaptors) {
#     my $db_connection = $db_adaptor->dbc();
# 
#     printf(
#         "species/group\t%s/%s\ndatabase\t%s\nhost:port\t%s:%s\n\n",
#         $db_adaptor->species(),   $db_adaptor->group(),
#         $db_connection->dbname(), $db_connection->host(),
#         $db_connection->port()
#     ) if $db_adaptor->species() =~ /_str_168/;
# }

#my $slice_adaptor = $registry->get_adaptor( 'Human', 'Core', 'Slice' );
my $sa = $registry->get_adaptor('bacillus_subtilis_subsp_subtilis_str_168','Core', 'slice');
my $chrom_ref = $sa->fetch_all('chromosome');
my @chroms = @{ $chrom_ref };

print "There are ", scalar(@chroms), " chromosomes\n";

foreach my $chrom (@chroms) {

#  print Dumper($chrom);

  my $circ = $chrom->is_circular();
  my $top = $chrom->is_toplevel();

  print 
  "Disp:\t", $chrom->display_id, "\n",
  "Chrom:\t", $chrom->seq_region_name, "\tLength: ", $chrom->end,"\n";
  print "Top level\n" if $circ;
  print "Is circular\n" if $circ;

  print
  $chrom->accession_number(), "\n",
  $chrom->coord_system()->version(), "\n",
#  $chrom->coord_system()->name(), "\n",
  $chrom->primary_id(), "\n";
#  $chrom->coord_system_name(), "\n";
#$chrom->dbID(), "\n",
#  $chrom->desc(), "\n";

}



# register_dbs(
# 		 "localhost", 3306, "ml590",
# 		 "ml590", "bacteria_[0-9]+_collection_core_20" );
# 
# my $lookup = Bio::EnsEMBL::LookUp->new(-CLEAR_CACHE => 1);
# 
# #my $lookup = Bio::EnsEMBL::LookUp->new();
# 
# #my ($dba) = @{$lookup->get_by_name_exact('escherichia_coli_str_k_12_substr_mg1655')};
# my ($dba) = @{$lookup->get_by_name_exact('bacillus_subtilis_subsp_subtilis_str_168')};

# my $host = 'localhost';
# my $port = '3306';
# my $user = 'ml590';
# my $pass = 'ml590';
# my $dbname = 'bacteria_18_collection_core_20';
# my $species = 'bacillus_subtilis_subsp_subtilis_str_168';
# 
#      my $dbCore = Bio::EnsEMBL::DBSQL::DBConnection->new(
#          -port    => $port,
#          -host    => $host,
#          -driver  => 'mysql',
#          -dbname  => $dbname,
#          -pass    => $pass,
#          -user    => $user,
#          -timeout => '0',
# 
#          -species => $species,
#          -group   => 'core'
#          ,   # This obviously needs to be changed if variations will be available
#      );
# 
# my $slice_adaptor = $dbCore->get_sliceAdaptor();
# my $slices        = $slice_adaptor->fetch_all('toplevel');

#print Dumper($slices);

#print %{ $dba{'Bio::EnsEMBL::DBSQL::DBAdaptor'} }, "\n";
#print $dba{'_dbc'}{'_port'}, "\n";
#%{ $dba {'_dbc'} }->{'_port'} = '12321';
#my %dbHash = %{ $dba };
#print $dbHash{'_dbc'}{'_port'}, "\n";
#print $dbHash{'_dbc'}{'_dbname'}, "\n";
#print $dba, "\n";

#print Dumper($dba);

# for my $gene (@{$dba->get_GeneAdaptor()->fetch_all_by_biotype('protein_coding')}) {
#   print $gene->external_name."\n";
# }

### Scratch ###
#my $lookup = Bio::EnsEMBL::LookUp->new(
#					-URL=>"http://bacteria.ensembl.org/registry.json",-NO_CACHE=>1,
#					Returntype => 'json');
#my $lookup = Bio::EnsEMBL::LookUp->new(-FILE=>"/home/ml590/MIKE/InterMine/SynBioMine/DataSources/Ensembl/reg.json");

#my ($dba) = @{$lookup->get_by_name_exact('escherichia_coli_str_k_12_substr_mg1655')};   
#my @dbas = @{$lookup->get_all_by_name_pattern('escherichia_coli_.*')};
#my $dba = $lookup->get_by_assembly_accession("GCA_000005845.1");

#my $genes = $dba->get_GeneAdaptor()->fetch_all();
#print "Found ".scalar @{ $genes }." genes for ".$dba->species()."\n";

