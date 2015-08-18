#!/usr/bin/perl

##use strict;
##use warnings;
use DBI;
use Config::Simple;
use Data::Dumper;

my %Config;
Config::Simple->import_from('db.config', \%Config);

#print Dumper(%Config);

my $dbh = connectToDatabase(%Config);

my $sql = "select proxyURL,  currPeriod_total_seconds / (currPeriod_bad+currPeriod_good) as AvgSecs from proxy where currPeriod_cummulative_good > 0 ";
my $arr_ref = getDataFromDatabase($dbh, $sql);
print Dumper($arr_ref);

$sql = "INSERT INTO `mydb`.`proxy`
(`proxyURL`,
`currPeriod_cummulative_good`,
`currPeriod_cummulative_bad`,
`currPeriod_bad`,
`currPeriod_good`,
`currPeriod_total_seconds`,
`prevPeriod_good`,
`prevPeriod_bad`)
VALUES
('192.168.1.1:8848',
50,
5,
500,
50,
3000,
3,
300)";
my $affected_rows = actionQueryForDatabase($dbh, $sql);
print "affected rows: $affected_rows\n";


sub connectToDatabase{

    my %Config = @_;

    #print "$Config{'mysql.dsn'},$Config{'mysql.user'}, $Config{'mysql.password'}\n";

    my $dbh = DBI->connect($Config{'mysql.dsn'},$Config{'mysql.user'},$Config{'mysql.password'},{'RaiseError' => 1});

    return $dbh;
}


sub getDataFromDatabase{

    my $dbh = shift @_;
    my $sql = shift @_;

    my $arr_ref = $dbh->selectall_arrayref($sql);

    return $arr_ref;

}

sub actionQueryForDatabase{

    my $dbh = shift @_;
    my $sql = shift @_;

    my $sth = $dbh->prepare($sql);
    my $affected_rows = $sth->execute;
    return $affected_rows;

}


sub disconnectDatabase{
    my $dbh = shift @_;
    $dbh->disconnect();
}

sub commitDatabase{
    my $dbh = shift @_;
    $dbh->commit;
}


1
