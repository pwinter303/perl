use strict;
use warnings;

#### Credit to: hbd in PerlMonks. Page: http://www.perlmonks.org/?node_id=1031825


my %joined;
my %headers;
#for my $file ( qw/file1.txt file2.txt file3.txt/ ) {
for my $file ( qw/Yahoo-KeyStats.csv Yahoo-IndustryInfo.csv Yahoo-AnalystOpinion.csv/ ) {
    readfile( $file, \%joined, \%headers );
}


sub readfile {
    my ( $filename, $hashref, $headref ) = @_;
    open my $fh, "<", $filename or die "Cannot open $filename!\n";
    my $headers = <$fh>;
    chomp $headers;
    #my @h = split /\s/, $headers;
    my @h = split /,/, $headers;
    #$headref->{$_}++ for @h[3..$#h];
    $headref->{$_}++ for @h[1..$#h];
    while( <$fh> ) {
        chomp;
        #my @line = split /\s/;
        my @line = split /,/;
        #$hashref->{$line[0]}{$line[1]}{$line[2]}{$h[$_]} = $line[$_] for 3..$#h;
        $hashref->{$line[0]}{$h[$_]} = $line[$_] for 1..$#h;
    }
    close $fh;
}

open my $fh, ">", "YahooResults.csv" or die "Cannot Open:YahooResults.csv!\n";

#print "ID NAME date ", join( " ", sort keys %headers ), "\n";
print $fh "Ticker", join( ",", sort keys %headers ), "\n";
for my $id ( sort keys %joined ) {
    ##for my $name ( sort keys %{$joined{$id}} ) {
        ##for my $date ( sort keys %{$joined{$id}{$name}} ) {
            ##print "$id $name $date ";
            print $fh "$id,";
            ##print join " ", map { $joined{$id}{$name}{$date}{$_} // "-+-" } sort keys %headers;
            print $fh join ",", map { $joined{$id}{$_} // "-+-" } sort keys %headers;
            print $fh "\n";
        ##}
    ##}
}
