#!/usr/local/bin/perl
use strict;
use warnings;

open my $file, 'caida.txt' or die "Failed\n";

#my @pkt_size = (64,128,256,384,512,640,768,896,1024,1504);
my @pkt_size = (64,128,256,384,512,640,896,1024,1280,1504);
my $i = 0;
my $prob = 0;
my $tot = 0;
my @probabilities;

while (my $line = <$file>) {

    if ($line =~ /^(\d+)\s*[\w\d\+\.]+\s+([0-9]+\.[0-9]+)\s+\d+/) {
	
	#if ($2 > 1) {print $line,"\n";}
	#print $line,"\n";

	if ($pkt_size[$i] <= $1) {
	    #print $pkt_size[$i]," ",$prob,"\n";
	    $probabilities[$i] = $prob;
	    $i++;  # go to next packet size
	    $prob = 0;
	}

	$prob += $2;
	$tot += $2;
    }

}

$probabilities[$i] = $prob;

for ($i=0;$i<10;$i++) {
    print $pkt_size[$i]," ",($probabilities[$i]/$tot)*100,"\n";
}
print $tot,"\n";
