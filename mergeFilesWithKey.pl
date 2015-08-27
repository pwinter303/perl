use strict;
use warnings;

use Data::Dumper;

#### Credit to: hbd in PerlMonks. Page: http://www.perlmonks.org/?node_id=1031825

my $outputFileName = "YahooResults.csv";


my %joined;
my @headersARR;
for my $file ( qw/Yahoo-KeyStats.csv Yahoo-IndustryInfo.csv Yahoo-AnalystOpinion.csv/ ) {
    readfile( $file, \%joined, \@headersARR);

}


sub readfile {
    my ( $filename, $hashref, $arrayref ) = @_;
    open my $fh, "<", $filename or die "Cannot open $filename!\n";
    my $headers = <$fh>;
    chomp $headers;  ### neeeded to remove carriage return
    my @h = split /,/, $headers;
    push(@$arrayref,@h[1..$#h]);
    while( <$fh> ) {
        chomp;
        my @line = split /,/;
        $hashref->{$line[0]}{$h[$_]} = $line[$_] for 1..$#h;
    }
    close $fh;
}


open my $fh, ">", $outputFileName or die "Cannot Open:$outputFileName!\n";

print $fh "ID,", join( ",", @headersARR ), "\n";
for my $id ( sort keys %joined ) {
            print $fh "$id,";
            print $fh join ",", map { $joined{$id}{$_} // "-+-" } @headersARR;
            print $fh "\n";
}

close $fh;

