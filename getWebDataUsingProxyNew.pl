#!/usr/bin/perl

use strict;
use warnings;

use WWW::FreeProxyListsCom;
use WWW::Mechanize;
use Data::Dumper;
require db.pl;

####################################################################################
sub getProxyURLsAndSaveToDatabase{
    (my $max_proxies, my $skipFile, my $skipWeb, my $skipTempFile = 1, my $dbh) = @_;

    my %proxyURLs = buildFullListOfProxyURLs($max_proxies,$skipFile, $skipWeb, $skipTempFile);

    addProxyURLsToDatabase(\%proxyURLs, $dbh);

}


####################################################################################
sub addProxyURLsToDatabase{
    my $refProxyURLs = shift @_;
    my $dbh = shift @_;

    foreach my $proxyURL (keys %{$refProxyURLs}) {
        print "ProxyURL:$proxyURL\n";
        #see if it exists
        #add it if it doesnt
        }
}




####################################################################################
sub getTestAndSaveProxyURLs{    
    (my $max_proxies, my $skipFile, my $skipWeb, my $skipTempFile) = @_;
 `
    my %proxyURLs = buildFullListOfProxyURLs($max_proxies,$skipFile, $skipWeb, $skipTempFile);

    filterProxyURLs(\%proxyURLs); 
    
    testProxyURLs(\%proxyURLs);
    
    outputProxyURLsToFile(\%proxyURLs, 1);  ### 1 means Merge

    calcStats(\%proxyURLs, 1); #1: Print the stats
    
}




####################################################################################
sub buildFullListOfProxyURLs{    
    (my $max_proxies, my $skipFile, my $skipWeb, my $skipTempFile) = @_;
    
    my %proxyURLs = ();

    print "=========  BUILDING THE LIST OF PROXIES ============";
    
    #### Get the Master Proxy File
    if (!($skipFile)){
        my $file = "ProxyURLs.csv";
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
sub filterProxyURLs{    

    (my $refProxyHash) = @_;

    my $refBadURLs = createListofBadProxyURLs();
    my $deletedProxyURLs = 0;
	
    #### remove the crappy URLs that have never had 1 successful hit..
    foreach  my $badURL (keys %{$refBadURLs}) {
        if ($refProxyHash->{$badURL}){
            if ($refBadURLs->{$badURL}){
                delete $refProxyHash->{$badURL};  #### only delete it if it's had more than 1 failure
                $deletedProxyURLs++;
            }
        }
    }
    
    print "$deletedProxyURLs ProxyURLs were deleted from the master list since they have been tested but never had a single success\n";
    
    ## No need to return anything since the refProxyHash is being updated directly
    
}

####################################################################################
sub createListofBadProxyURLs{
    my %badURLs = ();
    print "\n\n\nSTARTING BAD URL IDENTIFICATION\n";

    my @proxyFiles = <Proxy*.csv>;

    foreach my $file (@proxyFiles){
        findBadProxyURLs($file,\%badURLs);
    }
    
    my $hashCount = keys %badURLs;
    print "There are $hashCount ProxyURLs that are bad.  Meaning, We have tested the ProxyURL in the past but it never had a successful hit\n";
    
    return (\%badURLs);

}

####################################################################################
sub findBadProxyURLs{
    my $proxyFile = shift @_;
    my $refBadURLs = shift @_;
    
    my %proxyURLs = ();
    my $successRatio = 0;
    my $goodURL = 0;
    my $badURL = 0;
    my $neverCalled = 0;
    
    getProxysFromFile(\%proxyURLs, $proxyFile);
    
    foreach my $proxyURL (keys %{proxyURLs}) {
        my @fields = @{$proxyURLs{$proxyURL}};
        ### fields: 0=Attempts, 1=Successes, 2=Failures, 3=Ttl Seconds, 4=Avg Seconds     
        if ($fields[0]){
            $successRatio = int(($fields[1] / $fields[0]) * 100);
            
            if ($successRatio == 0){
                $refBadURLs->{$proxyURL}++;
                $badURL++;
            } else {
                #Possible that a URL could be Bad in one file but then it could be a success in a subsequent file. 
                #  In these situations we want to remove it from the list of badURLs so we can give it another chance.
                delete $refBadURLs->{$proxyURL};
                $goodURL++;
            }
        
        } else {
	    $neverCalled++;	
	}
    }
    print "found badURLs:$badURL and goodURLs:$goodURL  neverCalled:$neverCalled\n";
    
    return $refBadURLs;  ##FixMe: Can probably be deleted since the function uses a reference and the badURL hash is being updated
}



####################################################################################
sub testProxyURLs{    

    (my $refProxyHash) = @_;
        
    ###zeroStats(\%proxyURLs);
    zeroStats($refProxyHash);    
    
    ###testProxys($max_proxies, 8, \%proxyURLs, 2);  #MaxProxies, Timeout, Hash, Nbr of times to try a proxy
    testProxys(8, $refProxyHash, 2);  #Timeout, Hash, Nbr of times to try a proxy
    
    ## No need to return anything since the refProxyHash is being updated directly
    
}





####################################################################################   
sub testProxys{
    (my $timeout, my $refProxyHash, my $attempts) = @_;

    my $url = 'http://www.google.com';
    my $read = 0;
    my $tested = 0;
    foreach my $proxyURL (keys %{$refProxyHash}) {
	 $read++;	
	(my @fields) = @{$refProxyHash->{$proxyURL}};
	 ### fields: 0=Attempts, 1=Successes, 2=Failures, 3=Ttl Seconds, 4=Avg Seconds
	if (0 == $fields[0]){
	    $tested++;
	    ################print "\nProxies tested: $i\n";
	    getTheWebPage($url, $timeout ,$proxyURL, $refProxyHash, $attempts, 1); #url, timeout, proxyURL, reference to proxy hash, # of attempts, SkipProxyFreeCall
	}
	my $remainder = $read % 10;
	### If remainder is zero... its a multiple of 50 and we want to produce the stats
	if (0 == $remainder){
		print "\n\n\nProxyURLs Read: $read,   Tested: $tested  (NOTE: ProxyURLs are only tested if they dont have any stats... IE: They havent been tested before)\n";
		calcStats($refProxyHash, 1); #1: Print the stats
	}
    }

}



####################################################################################
sub zeroStats{    
    (my $refProxyHash) = @_;
    
    my @fields = (0,0,0,0,0);  # 0=Attempts, 1=Successes, 2=Failures, 3=Ttl Seconds, 4=Avg Seconds

    foreach my $proxyURL (keys %{$refProxyHash}) {
         @{$refProxyHash->{$proxyURL}} = (@fields);
    }
}


####################################################################################
sub outputProxyURLsToFile{
    (my $refProxyHash, my $merge = 1) = @_;
	
    (my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) = localtime(time);
    $year += 1900;
    $mon += 1;
    my $now_string = "$year-" . sprintf("%02d", $mon) . "-" .  sprintf("%02d", $mday) . "-" .  sprintf("%02d", $hour).  sprintf("%02d", $min) . sprintf("%02d", $sec);
    
    ## Backup the Current MASTER Proxy File
    my $fileIn = "ProxyURLs.csv";
    my $fileBackup = ">" . "ProxyURLs-$now_string.csv";
    open (OUTMSTR, "$fileBackup") ||die "can't open Backup ProxyFile:$fileBackup";
    
    if (-e $fileIn){
        open (IN1, "$fileIn") ||die "can't open ProxyFile: $fileIn";
        while (<IN1>){
	        print OUTMSTR $_;
        }
    }
    close IN1;
    close OUTMSTR;
    
    if ($merge){
        my $file = "ProxyURLs.csv";
        print "\n\nGetting ProxyURLs from the MasterFile:$file... So they can be merged with the current stats\n";
        #### this function reads the master file and combines stats with anything that already exists in the refProxyHash
        getProxysFromFile($refProxyHash, $file);
    }
    
    ## Write the results of the current run to the MASTER Proxy File
    my $filenameOutput = ">" . "ProxyURLs.csv";
    open (OUTMSTR, "$filenameOutput") ||die "can't open ProxyFile:$filenameOutput";
    
    foreach my $proxyURL (keys %{$refProxyHash}) {
        (my @fields) = @{$refProxyHash->{$proxyURL}};
        print OUTMSTR "$proxyURL," . join(',', @fields) . "\n";
    }
    close OUTMSTR;
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
            ##chop;
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

####################################################################################   
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
sub getSingleProxy{
	my $refProxyHash = shift @_;
    
    my $proxyURL = "";
	my @proxies =();
	my $targetNumber = 15;  ### take the best proxyURLs based on latency/avg seconds.

    my %latency = calcStats($refProxyHash, 0);

	foreach my $key (sort {$a<=>$b}  keys %latency){
		push (@proxies, @{$latency{$key}});
        ##print "Adding proxies to array to search: " . @{$latency{$key}} . " added. Latency is $key. Now there are: " . @proxies . " in the array\n";
		if ($#proxies > $targetNumber){
			last;
		}
	}
	my $item = int(rand($#proxies));
	$proxyURL = $proxies[$item];
    if (!($proxyURL)){
        print "in getSingleProxy..and something is odd\n\n\n";
        print "this is dump of proxies array";
        print Dumper(@proxies);
        print "this is dump of latency hash";
        print Dumper(%latency);
        print "this is dump of proxy hash";
        print Dumper($refProxyHash);
        print "this is the item number we are going after:$item";
        print "this is the proxyURL:$proxyURL";
        ####die;
    }
    
    
    if (length($proxyURL) < 5){
        print "\n\n\n\n ERROR ERROR ERROR something went wrong in getSingleProxy. Here is proxyURL:$proxyURL. This is the item:$item.  This is the count of items. $#proxies\n";
        print "this is proxies array -->" . Dumper(@proxies) . "<-----\n";
        $proxyURL = "http://190.207.33.80:8080";  #### complete hack just to keep the script going....
    }

	return $proxyURL;
}

####################################################################################   
sub calcStats{
	(my $refProxyHash, my $printStats) =  @_;
    
    my %latency = ();
    my $successRatio = 0;
    my $proxyURL = "";
    my @proxies =();
    my $good = 0;
    my $bad = 0;
    my $untested = 0;
    
    foreach  $proxyURL (keys %{$refProxyHash}) {
        (my @fields) = @{$refProxyHash->{$proxyURL}};
        if ($fields[0]){
            $successRatio = int(($fields[1] / $fields[0]) * 100);
            if ($successRatio > 50){
                push @{$latency{$fields[4]}}, $proxyURL;
                $good++;
            } else {
                $bad++;
            }
        } else {
                $untested++;
        }
    }
       
    if ($printStats){
        print "\nBreakdown of ProxyURLs-->  Good: $good Bad:$bad Untested:$untested  (GOOD is more than 50% of the attempts were successful) \n";
        print "\nAverage Response Time (Seconds):Number Of ProxyURLs\t";
        foreach my $key (sort {$a<=>$b}  keys %latency){
            print "$key:" . @{$latency{$key}} . "  " ;
        }
        print "\n\n";
    }
    
    return %latency;

}



####################################################################################   
sub getTheWebPage {
    (my $url, my $timeout, my $proxyURL, my $refProxyHash, my $maxTries, my $skipProxyFreeCall) = @_;
    
    my $success = 0;
    my $content = "";
    my @fields = ();
    my %hashStats = ();
    if (!($maxTries)){$maxTries = 2;}
    $maxTries = $maxTries - 1; ### since the array starts at zero
    
    
    
    ##FixMe: Update this function so it calls... getSingleProxy.
    ##       And add logic that if a call fails more than maxTries then this function should get another proxy
    ##       and continue until it works....
    until ($success){
        my $i=0;
        for ($i = 0; $i <= $maxTries; $i++) {
            ##print "maxTries:$maxTries\n";
            my $now = time;
            ($success,$content) = getWebPageDetail($url,$timeout,$proxyURL);
            my $seconds = time - $now;
            ### fields: 0=Attempts, 1=Successes, 2=Failures, 3=Ttl Seconds, 4=Avg Seconds
            (@fields) = @{$refProxyHash->{$proxyURL}};
            $fields[0]++;
            $fields[3] += $seconds;
            if ($success){
                 $fields[1]++;
            } else {
                 $fields[2]++;
            }
            if ($fields[0]){
                $fields[4] = int($fields[3] / $fields[0]);
            }
	    ##########################print "URL:$proxyURL\tAttempts:$fields[0]\tSuccess:$success\tOK:$fields[1]\tBad:$fields[2]\tSecs:$fields[4]\t\n";
            $refProxyHash->{$proxyURL} = [@fields];
            if ($success){
                last;  ### call worked.. get out of loop... FixMe: Is this even needed???
            }
        }
        if (!($success)){
            if (!($skipProxyFreeCall)){
                print "\nThis Proxy:$proxyURL is bad.. Getting the webpage without a proxy\n";
                ($success, $content) = getWebPageDetail($url,$timeout,0); # URL, Timeout, ProxyURL (0 doesnt use Proxy)
            }
            last; #regardless of the success... get out....
        }
    }
    return $content;
}

####################################################################################   
sub getWebPageDetail {
	(my $url, my $timeout, my $proxyURL) = @_;
    
    my $content = "";
    my $success = 0;
    my $mech1 = WWW::Mechanize->new( autocheck => 0, timeout=>$timeout);
    if ($proxyURL){
        $mech1->proxy(['http', 'ftp'], $proxyURL);
    } else {
        #### getting the web detail without proxy.. this is done when the function is called without proxy being passed....
        ####print "ProxyFail:PassedProxy:$proxyURL<-- Will call without proxy";
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
