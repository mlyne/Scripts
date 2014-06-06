#!/usr/local/bin/perl -w

#*************************************************************
# $Id: getHitData.pl,v 1.2 2000/10/10 15:07:18 Mahini Exp $
# Purpose:
#	To update perl location from:
#		#!/usr/bin/perl -w
#	To:
#		#!/usr/local/bin/perl -w
#	(Note: Based on the old perl location error message:
#		"Command Not Found" was being generated)
#*************************************************************
#
#  $Id: getHitData.pl,v 1.1 1999/08/09 21:35:18 volkmuth Exp $

use strict;
use DBI;

my $userpass;
my $dbname='bobqa';

$userpass = $ENV{'DBCONNECT'};

my $dbh;

$dbh = DBI->connect($dbname, $userpass, '', 'Oracle');

if (! defined $dbh) {
    die "Failed to connect : $userpass\n$DBI::errstr\n";
}

my $query;

$query = "select ha.wip_id, dbe.dbentryid, dbe.description, dbs.dbname, har.metricvalue from
wip w,
databaseentry dbe, databasesource dbs, hitannotation ha,
hitannotationresult har where
w.wip_id = ha.wip_id and
w.tophitannotationid = ha.hitannotationid and
ha.hitannotationid = har.hitannotationid and
har.metrictype = 'EVALUE' and
dbe.dbentrykey = ha.dbentrykey and dbe.dbsourcekey = dbs.dbsourcekey
order
by ha.wip_id";

my $cursor = $dbh->prepare($query);

if ( !defined $cursor) {
    die "Can't prepare statment : $query\n$DBI::errstr\n";
}

$cursor->execute;

my @row;
while (@row = $cursor->fetchrow()) {
    print join("\t", @row), "\n";
}

$cursor->finish;

$dbh->disconnect;
