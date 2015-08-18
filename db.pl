#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use Data::Dumper;

#my %Config;
#Config::Simple->import_from('db.config', \%Config);

#print Dumper(%Config);

#my $dbh = connectToDatabase(%Config);



#####################################################
sub connectToDatabase{
    my %Config = @_;
    my $dbh = DBI->connect($Config{'mysql.dsn'},$Config{'mysql.user'},$Config{'mysql.password'},{'RaiseError' => 1});
    return $dbh;
}


#####################################################
sub getDataFromDatabaseReturnAoH{
    ### this returns an Array of Hashes
    ### Use this to process the results (replace proxyURL & AvgSecs with the real column names
    #        foreach my $row (@$arr_ref) {
    #            print "$row->{proxyURL}\t$row->{AvgSecs}\n";
    #        }

    my $dbh = shift @_;
    my $sql = shift @_;
    my $arr_ref = $dbh->selectall_arrayref($sql,{Slice=>{}});
    ###selectall_arrayref($query,{Slice=>{}})
    return $arr_ref;
}

#####################################################
sub actionQueryForDatabase{
    my $dbh = shift @_;
    my $sql = shift @_;
    my $sth = $dbh->prepare($sql);
    my $affected_rows = $sth->execute;
    return $affected_rows;
}

#####################################################
sub disconnectDatabase{
    my $dbh = shift @_;
    $dbh->disconnect();
}

#####################################################
sub commitDatabase{
    my $dbh = shift @_;
    $dbh->commit;
}


1
