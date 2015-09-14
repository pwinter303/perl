#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Config::Simple;
use POSIX;

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
    my $n =     shift;
    return(($n == int($n)) ? $n : int($n + 1))
}

sub getConfig{
    my $configFile = shift @_;
    my %Config;
    Config::Simple->import_from($configFile, \%Config);
    return \%Config;
}

sub getTickers{
    my $file = shift @_;
    open my $handle, '<', $file ||die "cant open symbol file: $file";
    chomp(my @tickers = <$handle>);
    close $handle;
    return \@tickers;
}



sub runTimeNow{
    my $now = shift @_;
    $now = time - $now;

    printf(
    "\nTotal running time in $0: %02d:%02d:%02d\n",
    int( $now / 3600 ),
    int( ( $now % 3600 ) / 60 ),
    int( $now % 60 )
    );
}

sub expandValue {
    my $val = shift @_;

    my %factors = (
        'K' => 3,
        'M' => 6,
        'B' => 9,
        'T' => 12 ## for when we have the first trillion dollar company.
    );

    if ($val =~ s/(K|M|B|T)// ) {
        my $shift = $factors{$1};  #$1 is K, M, B or T  (from above)
        $val = _decimal_shiftup ($val, $shift);
    } # end If
    return $val;

} #end of SUB


# $str is a number like "123" or "123.45"
# return it with the decimal point moved $shift places to the right
# must have $shift>=1
# eg. _decimal_shiftup("123",3)    -> "123000"
#     _decimal_shiftup("123.45",1) -> "1234.5"
#     _decimal_shiftup("0.25",1)   -> "2.5"
#
sub _decimal_shiftup {
    my ($str, $shift) = @_;

    # delete decimal point and set $after to count of chars after decimal.
    # Leading "0" as in "0.25" is deleted too giving "25" so as not to end up
    # with something that might look like leading 0 for octal.
    my $after = ($str =~ s/(^0)?\.(.*)/$2/ ? length($2) : 0);
    $shift -= $after;
    # now $str is an integer and $shift is relative to the end of $str

    if(   $str =~ m/
        \(  # A real bracket
        (   # Capture the output
        \d+ # One or more digits
        )   # Stop capturing
        \)  # The closing real bracket
        /x){
        ###print "Adjusting Negative... str is:$str 1 is:$1<--\n";
        $str = $1 * -1
    };

    if ($shift >= 0) {
    # moving right, eg. "1234" becomes "12334000"
    return $str . ('0' x $shift);  # extra zeros appended
    } else {
    # negative means left, eg. "12345" becomes "12.345"
    # no need to prepend zeros since demanding initial $shift>=1
    substr ($str, $shift,0, '.');  # new '.' at shifted spot from end
    return $str;
    }
}

sub getLastModifiedDate{
    my $file = shift @_;

    my $date = POSIX::strftime(
                 "%m/%d/%Y",
                 localtime(
                     ( stat $file )[9]
                     )
                 );
}

1 #return true;
