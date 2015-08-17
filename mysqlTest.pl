  #!/usr/bin/perl

  use strict;
  use warnings;
  use DBI;
  

  # Connect to the database.
  my $dbh = DBI->connect("DBI:mysql:database=mydb;host=localhost",
                         "perl_script", "xxxxxxx",
                         {'RaiseError' => 1});
                         
my $sql = "select proxyURL,  currPeriod_total_seconds / (currPeriod_bad+currPeriod_good) as AvgSecs from proxy where currPeriod_cummulative_good > 0 ";


my $all = $dbh->selectall_arrayref($sql);

foreach my $row (@$all) {
    my ($proxyURL, $AvgSecs) = @$row;
    print "$proxyURL $AvgSecs\n";
}

$dbh->disconnect();



