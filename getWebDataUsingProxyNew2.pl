#!/usr/bin/perl

use strict;
use warnings;

use WWW::FreeProxyListsCom;
use WWW::Mechanize;
use Data::Dumper;
use Config::Simple;

require "db.pl";

my %Config;
Config::Simple->import_from('db.config', \%Config);

my $dbh = connectToDatabase(%Config);

addProxysThenTestNewlyAdded($dbh);
getProxyURLsForUse($dbh);

###getProxyURLsAndSaveToDatabase(999,0,1,1,$dbh);


###############################################################################TEST
sub addProxysThenTestNewlyAdded{
    my $dbh = shift @_;
    getProxyURLsAndSaveToDatabase(9990,1,0,1,$dbh); #maxProxies, SkipFile, SkipWeb, SkipTemp
    test($dbh, 0);

}

####################################################################################
sub addProxysThenTestAll{
    my $dbh = shift @_;
    getProxyURLsAndSaveToDatabase(9990,0,1,1,$dbh);
    test($dbh, 1);
}

####################################################################################
sub getProxyURLsForUse{
    my $dbh = shift @_;
    my %proxyURLs;
    my $sql = "select proxyURL,  currPeriod_cummulative_good, currPeriod_cummulative_bad,
            (currPeriod_total_seconds / (currPeriod_bad+currPeriod_good)) as AvgSecs
            from proxy where currPeriod_cummulative_good > 0 order by AvgSecs";
    my $arr_ref = getDataFromDatabaseReturnAoH($dbh, $sql);
    foreach my $row (@$arr_ref) {
        my $proxyURL = $row->{proxyURL};
        my @array = ($row->{currPeriod_cummulative_good}, $row->{currPeriod_cummulative_bad}, $row->{AvgSecs});
        $proxyURLs{$proxyURL}= [@array];
        ##print "$proxyURL\t$row->{AvgSecs}\n";
    }
    my $count = keys %proxyURLs;
    if ($count < 5){
    $sql = "select proxyURL,  currPeriod_cummulative_good, currPeriod_cummulative_bad,
            (currPeriod_good / (currPeriod_bad+currPeriod_good)) as SuccessRatio,
            (currPeriod_total_seconds / (currPeriod_bad+currPeriod_good)) as AvgSecs
            from proxy where currPeriod_cummulative_good > 0 order by SuccessRatio";
    }
    $arr_ref = getDataFromDatabaseReturnAoH($dbh, $sql);
    foreach my $row (@$arr_ref) {
        my $proxyURL = $row->{proxyURL};
        my @array = ($row->{currPeriod_cummulative_good}, $row->{currPeriod_cummulative_bad}, $row->{AvgSecs});
        $proxyURLs{$proxyURL}= [@array];
        ##print "$proxyURL\t$row->{AvgSecs}\t$row->{SuccessRatio}\n";
    }

    return %proxyURLs;

    #print "\n\n";
    #print Dumper($arr_ref);
    #print Dumper(%proxyURLs);
}


####################################################################################
sub test{
    my $dbh = shift @_;
    my $testAll = shift @_;

    my %proxyURLs;

    my $sql = "select proxyURL from proxy where currPeriod_good = 0 and currPeriod_bad = 0";  #default to new
    if ($testAll){
        $sql = "select proxyURL from proxy";  ## override sql if testing all
    }
    my $arr_ref = getDataFromDatabaseReturnAoH($dbh, $sql);
    foreach my $row (@$arr_ref) {
        my $proxyURL = $row->{proxyURL};
        $proxyURLs{$proxyURL}=0;
    }
    #FixMe: Split the URLs into 6 (?) different groups and run 6 threads concurrently
    my $count = keys %proxyURLs;
    print "Retrieved $count proxies from the database... now starting the testing process \n";
    NEWtestProxyURLs(\%proxyURLs, $dbh);

}


####################################################################################
sub getProxyURLsAndSaveToDatabase{
    (my $max_proxies, my $skipFile, my $skipWeb, my $skipTempFile = 1, my $dbh) = @_;

    my %proxyURLs = buildFullListOfProxyURLs($max_proxies,$skipFile, $skipWeb, $skipTempFile);

    addProxyURLsToDatabase(\%proxyURLs, $dbh);

}


####################################################################################
sub buildFullListOfProxyURLs{
    (my $max_proxies, my $skipFile, my $skipWeb, my $skipTempFile) = @_;

    my %proxyURLs = ();

    print "=========  BUILDING THE LIST OF PROXIES ============";

    #### Get the Master Proxy File
    if (!($skipFile)){
        my $file = "../ProxyURLs.csv";
        print "\n\nGetting ProxyURLs from the MasterFile:$file\n";
        getProxysFromFile(\%proxyURLs, $file);
    }

    #### Get the Proxy from the Web
    if (!($skipWeb)){
        print "\n\nGetting ProxyURLs from the Web\n";
        getProxysFromWeb($max_proxies, \%proxyURLs);
    }

    #######  IN THIS SECTION... Make a TEMP Proxy file by copy/pasting from the sites below..
    ###########  http://www.gatherproxy.com/  8 Good out of 50
    ###########  http://www.us-proxy.org/  55 Good out of 200
    ###########  http://proxylist.hidemyass.com/search-1300902#listable    11 Good out of 70
    ###########  http://www.freeproxylists.net Download... Save to TXT
    #### Get the Temp Proxy File
    if (!($skipTempFile)){
        my $tempFile = "myTempProxyFile.txt";
        print "\n\nGetting ProxyURLs from the TempFile:$tempFile\n";
        getProxysFromTempFile(\%proxyURLs, $tempFile);
    }

    return %proxyURLs;
}




####################################################################################
sub addProxyURLsToDatabase{
    my $refProxyURLs = shift @_;
    my $dbh = shift @_;

    foreach my $proxyURL (keys %{$refProxyURLs}) {

        my $sql = "select count(*) as Count from proxy where proxyURL = '$proxyURL'";
        my $arr_ref = getDataFromDatabaseReturnAoH($dbh, $sql);
        my $count = 0;
        foreach my $row (@$arr_ref) {
            $count = $row->{Count};
        }
        print "ProxyURL:$proxyURL\tcount:$count\n";
        unless ($count){
            $sql = "insert into proxy (proxyURL, currPeriod_cummulative_good, currPeriod_cummulative_bad, currPeriod_bad,
                    currPeriod_good, currPeriod_total_seconds, prevPeriod_good, prevPeriod_bad)
                    VALUES
                    ('$proxyURL',0,0,0,0,0,0,0)";
            #print "SQL:$sql\n";
            my $affected_rows = actionQueryForDatabase($dbh, $sql);
            print "inserted rows: $affected_rows\n";
        }

    }
    ## not necessary since autocommit is enabled.
    ###commitDatabase($dbh);

}




####################################################################################
sub NEWtestProxyURLs{
    my $refProxyURLs = shift @_;
    my $dbh = shift @_;

    my $total_good = 0;
    my $total_bad = 0;
    my $total_seconds = 0;
    my $cummulative_good = 0;
    my $cummulative_bad = 0;
    my $sql = "";
    my $affected_rows = 0;
    my $i = 0;
    foreach my $proxyURL (keys %{$refProxyURLs}) {
        ($total_good, $total_bad, $total_seconds, $cummulative_good, $cummulative_bad) = NEWtestProxy(8, $proxyURL, 6, 'http://www.google.com');

        print "$proxyURL -> GOOD:$total_good, BAD:$total_bad, SECS:$total_seconds, CUMM_GOOD:$cummulative_good, CUMM_BAD:$cummulative_bad \n";

        ### FixMe: Add CurrPeriod to Prior Period
        $sql = "update proxy set prevPeriod_good = prevPeriod_good + currPeriod_good where proxyURL = '$proxyURL'";
        $affected_rows = actionQueryForDatabase($dbh, $sql);
        print "update $affected_rows row.. moving currPeriod to priorPeriod\n";

        ### FixMe: Update CurrPeriod with Test Results
        $sql = "update proxy set currPeriod_good = $total_good,  
                                 currPeriod_bad = $total_bad,
                                 currPeriod_total_seconds = $total_seconds,
                                 currPeriod_cummulative_good = $cummulative_good,
                                 currPeriod_cummulative_bad = $cummulative_bad
                                where proxyURL = '$proxyURL'";
        $affected_rows = actionQueryForDatabase($dbh, $sql);
        print "update $affected_rows row.. with results from the test\n";
        $i++;
        unless ($i % 10){
            my $t = localtime;
            print "completed $i $t\n";
        }

    }
}

####################################################################################
sub NEWtestProxy{
    (my $timeout, my $proxyURL, my $attempts, my $url) = @_;
    my $total_good = 0;
    my $total_bad = 0;
    my $total_seconds = 0;
    my $cummulative_good = 0;
    my $cummulative_bad = 0;

    my $success;
    my $content;

    my $i=0;
    for ($i = 0; $i <= $attempts; $i++) {
        my $now = time;
        ### STUB FIXME:
        ($success,$content) = getWebPageDetail($url,$timeout,$proxyURL);
        ###($success,$content) = STUBgetWebPageDetail($url,$timeout,$proxyURL);
        my $seconds = time - $now;
        $total_seconds += $seconds;
        if ($success) {
            $total_good++;
            $cummulative_bad = 0;
            $cummulative_good++;
        } else {
            $total_bad++;
            $cummulative_good = 0;
            $cummulative_bad++;
        }
        #print "$proxyURL -> GOOD:$total_good, BAD:$total_bad, SECS:$total_seconds, CUMM_GOOD:$cummulative_good, CUMM_BAD:$cummulative_bad \n";
    }

    return ($total_good, $total_bad, $total_seconds, $cummulative_good, $cummulative_bad);

}



####################################################################################
sub getProxysFromTempFile{
    my $refProxyHash = shift @_;
    my $file = shift @_;

    my @fields = ();
    my $recs = 0;

    if (-e $file){
        open (IN1, "$file") ||die "can't open input $file";
        while (<IN1>){
            $recs++;
            chomp;
            my $line = $_;
            print $line . "\n";
            if ($line =~ m/\d+\./){
		my $url = 'http://' . $line;
		if ( ($url) and ($url =~ m/http/) ){
		    ##print "ADDING: $url\n";
		    ##FixMe: I don think this is needed since the zeroStats is called before the test run...
		    my @fields = (0,0,0,0,0);  # 0=Attempts, 1=Successes, 2=Failures, 3=Ttl Seconds, 4=Avg Seconds
		    $refProxyHash->{$url} = [@fields];
		}
	    }
        }
        close IN1;
    } else {
        print "Proxy File Not Found! $file \n\n";
    }

    ###my $hashCount = keys %{$refProxyHash};
    print "Retrieved $recs from the Proxy File:$file\n";
}




####################################################################################
sub getProxysFromFile{

    my $refProxyHash = shift @_;
    my $file = shift @_;

    my @fields = ();
    my $recs = 0;

    ##FixMe: Instead of having temp should this be used to grab the temp files????? YES....  Changes Required:  Temp File wont have http... Temp file wont have stats (so cant split)

    if (-e $file){
        open (IN1, "$file") ||die "can't open input $file";
        while (<IN1>){
            chomp;
            $recs++;
            @fields = split "," , $_;
            if ( ($fields[0]) and ($fields[0] =~ m/http/) ){
                my $url = shift @fields;
                ### fields (AFTER shift): 0=Attempts, 1=Successes, 2=Failures, 3=Ttl Seconds, 4=Avg Seconds

                if ($refProxyHash->{$url}){
                    (my @fieldsExisting) = @{$refProxyHash->{$url}};
                    for (my $i = 0; $i <= 3; $i++) {
                        $fields[$i] += $fieldsExisting[$i];  ### Combine stats when duplicate is found
                    }
                    if ($fields[1]){
                        $fields[4] = int($fields[3]/$fields[0]); ## Calc average seconds
                    }
                }
                $refProxyHash->{$url} = [@fields];
            }
        }
        close IN1;
    } else {
        print "Proxy File Not Found! $file \n\n";
    }
    ##my $hashCount = keys %{$refProxyHash};
    print "Retrieved $recs from the Proxy File:$file\n";
}

###################################################################################
sub getProxysFromWeb {
    (my $max_proxies, my $refProxyHash) = @_;

    my $prox = WWW::FreeProxyListsCom->new;

    ### there are 100 proxys per page.... so max_pages => 4 will give you 400..... if you do max_pages => 0  you'll get the max which is 2100
    my $ref = $prox->get_list( type => 'anonymous', max_pages => 0 ) or die $prox->error;

    my $added=0;
    my $metCriteria = 0;
    my %junkHash = ();

	foreach my $proxy_info (@$ref) {
		my $proxy_address = $proxy_info->{ip};
        ### my $latency = $proxy_info->{latency};
        ### I question how accurate the latency measurement really is.... removed check in order to get more proxyURLs
		##if (($proxy_address =~ m/\d/) and ($latency < 6500)){
        if ($proxy_address =~ m/\d/){
            $metCriteria++;
            my $foundIPPort = "http://$proxy_info->{ip}:$proxy_info->{port}";
            if (!($refProxyHash->{$foundIPPort})){
                $refProxyHash->{$foundIPPort} = [(0,0,0,0,0)];
                $added++;
            } else {
                #print "Didnt Add This Web ProxyURL because it existed... I think... $foundIPPort\n";
                #print "this is the value in the ref hash:\n";
                #print Dumper($refProxyHash->{$foundIPPort});
                $junkHash{$foundIPPort}++;  ### Used this to verify the dups
            }
		}
	}
    print "Retrieved " . @$ref . " proxies from the web.  $metCriteria met the latency criteria. $added were added to hash (the rest already existed, or they were dups)\n";

    #####print Dumper(%junkHash);
}



####################################################################################
sub STUBgetWebPageDetail {
    my $content = "HELLERRRR";
    my $success = 1;
    sleep 1;
	return ($success,  $content);
}

####################################################################################
sub getWebPageDetail {
	(my $url, my $timeout, my $proxyURL) = @_;

    my $content = "";
    my $success = 0;
    my $mech1 = WWW::Mechanize->new( autocheck => 0, timeout=>$timeout);
    if ($proxyURL){
        $mech1->proxy(['http', 'ftp'], $proxyURL);   #specifies to use proxy for all http and ftp requests
    }
    $mech1->agent_alias("Windows Mozilla");    ### flips it to MOZILLA
    my $result = $mech1->get($url);
    if ($result->is_success){
        $success = 1;
        $content = $mech1->content;
    } else {
        $success = 0;
    }
	return ($success,  $content);
}



1
