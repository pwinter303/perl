use strict;
use warnings;

use Data::Dumper;

#### Credit to: hbd in PerlMonks. Page: http://www.perlmonks.org/?node_id=1031825

my $outputFileName = "YahooResults.csv";
my @arrFiles = qw/Yahoo-IndustryInfo.csv Yahoo-KeyStats.csv  Yahoo-AnalystOpinion.csv/ ;

mergeTheFiles(\@arrFiles, $outputFileName);


sub mergeTheFiles{
    my ($fileref, $outName) = @_;
    my %joined;
    my @headersARR;
    for my $file (@$fileref) {
        readfile( $file, \%joined, \@headersARR);
    }

    writefile($outName, \%joined, \@headersARR)
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

sub writefile {
    my ( $filename, $hashref, $arrayref ) = @_;
    open my $fh, ">", $filename or die "Cannot Open:$filename!\n";

    print $fh "ID,", join( ",", @$arrayref ), "\n";
    for my $id ( sort keys %$hashref ) {
                print $fh "$id,";
                print $fh join ",", map { $$hashref{$id}{$_} // "-+-" } @$arrayref;
                print $fh "\n";
    }

    close $fh;
}
