#!/usr/bin/perl
use Data::Dumper;

use strict;
use warnings;

splitFile("symbols.csv","MySymbolsOut","csv",8);


sub splitFile {

    my $inputFileName = shift @_;
    my $OutputFileName = shift @_;
    my $OutputFileNameSuffix = shift @_;
    my $filesDesired = shift @_;

    my $recs = 0;
    open (MYINPUT, $inputFileName) or die "Can't open $inputFileName!";
    $recs++ while (<MYINPUT>);
    close MYINPUT;
    print "$recs in inputFile\n";

    my $recs_per_file = roundup($recs / $filesDesired);

    if ($recs < $filesDesired){$filesDesired = $recs;}

    my $nbrOfFiles = 1;
    my $outFile = $OutputFileName . sprintf("%02d", $nbrOfFiles) . ".$OutputFileNameSuffix";
    open (MYOUTPUT, '>',$outFile);

    open (MYINPUT, $inputFileName) or die "Can't open $inputFileName!";
    while (<MYINPUT>) {
        print MYOUTPUT $_;

        unless ($. % $recs_per_file) {
          close MYOUTPUT;
          $nbrOfFiles++;
          $outFile = $OutputFileName . sprintf("%02d", $nbrOfFiles) . ".$OutputFileNameSuffix";
          open MYOUTPUT, '>', "$outFile" or die $!;
        } #end of UNLESS
    } #end of WHILE
}


sub roundup {
    my $n = shift;
    return(($n == int($n)) ? $n : int($n + 1))
}
