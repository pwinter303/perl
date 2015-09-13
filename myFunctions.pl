#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

### Credit for this: Brad Gilbert @ http://stackoverflow.com/questions/1490896/how-can-i-partition-a-perl-array-into-equal-sized-chunks
sub splitArray {
    my ($numberOfArraysDesired, $arrayRef ) = @_;
    my $countOfItems = @$arrayRef;
    my $itemsPerArray = roundup($countOfItems / $numberOfArraysDesired);
    my @hashes;
    my @VAR;
    push @VAR, [ splice @$arrayRef, 0, $itemsPerArray ] while @$arrayRef;
    return \@VAR;
}

### Credit for this: Diab Jerius @ http://stackoverflow.com/questions/27403978/split-a-hash-into-many-hashes
sub splitHash {
    my ($numberOfHashesDesired, $hash ) = @_;
    my @keys = keys %$hash;
    my $countOfItems = @keys;
    my $itemsPerHash = roundup($countOfItems / $numberOfHashesDesired);
    my @hashes;
    while ( my @subset = splice( @keys, 0, $itemsPerHash ) ) {
        push @hashes, { map { $_ => $hash->{$_} } @subset };
    }
    return \@hashes;
}

sub roundup {
    my $n = shift;
    return(($n == int($n)) ? $n : int($n + 1))
}

sub getTickers{
    my $pathBase = shift @_;
    my $symbolFileName = shift @_;
    my $file =  $pathBase . $symbolFileName;
    open my $handle, '<', $file ||die "cant open symbol file: $file";
    chomp(my @tickers = <$handle>);
    close $handle;
    return \@tickers;
}


1 #return true;
