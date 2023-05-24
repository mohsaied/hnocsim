#!/usr/local/bin/perl
use strict;
use warnings;

use constant SEED => 15801;
use constant SAMPLES => 5;

srand(SEED);

open (DATA,">stress_latency.txt") or die "dead\n";
open my $file, 'switch_config' or die "Failed\n";

my $in_rate = -1;
while (my $line = <$file>) {
    if ($line =~ /^injection_rate\s*=\s*([0-9]*\.?[0-9]*);/) {
	$in_rate = $1;
    }
}

#for (my $in_rate=0.01; $in_rate<=0.3; $in_rate+=0.01) {

    my @max_channel_load;
    my $avg_load = 0;
    my $max_load = 0;
    my $max_seed;
    my $avg_pkt_lat = 0;
    my $max_pkt_lat = 0;
    my $avg_flit_lat = 0;
    my $max_flit_lat = 0;
    my $avg_net_lat = 0;
    my $max_net_lat = 0;

    for (my $i=0; $i<SAMPLES; $i++) {
	#print int(rand(10000)),"\n";

	my $seed = int(rand(1000000000));
	my $result = `/home/andrew/booksim2-master/src/booksim switch_config sample_period=10000 seed=$seed`;

	my $max_activity;
	while ($result =~ /Max channel activity = (\d+) cycles/g) {
	    $max_activity = $1
	}

	
	while ($result =~ /Packet latency average = ([0-9]*\.?[0-9]*) \(1 samples\).*\n.*minimum = \d+ \(1 samples\).*\n.*maximum = (\d+)/g) {
	    $avg_pkt_lat += $1;
	    #$max_pkt_lat += $2;
	    if ($2 > $max_pkt_lat) {
		$max_pkt_lat = $2;
	    }
	}
	
	

	while ($result =~ /Flit latency average = ([0-9]*\.?[0-9]*) \(1 samples\).*\n.*minimum = \d+ \(1 samples\).*\n.*maximum = (\d+)/g) {
	    $avg_flit_lat += $1;
	    #$max_flit_lat += $2;
	    if ($2 > $max_flit_lat) {
		$max_flit_lat = $2;
	    }
	}
	
	while ($result =~ /Network latency average = ([0-9]*\.?[0-9]*) \(1 samples\).*\n.*minimum = \d+ \(1 samples\).*\n.*maximum = (\d+)/g) {
	    $avg_net_lat += $1;
	    #$max_flit_lat += $2;
	    if ($2 > $max_net_lat) {
		$max_net_lat = $2;
	    }
	}
	
	

	my $tot_cycles = 0;
	while ($result =~ /Time taken is (\d+) cycles/g) {
	    $tot_cycles = $1;
	}

	if ($tot_cycles == 0) {
	    print $result;
	    print "\nFailed with seed = ",$seed,"\n";
	}

	#$max_channel_load[$i] = $mcl/$tot_cycles;

	my $load = $max_activity/$tot_cycles;
#
#	if ($max_load < $load) {
#	    $max_load = $load; 
#	    $max_seed = $seed;
#	}

	$avg_load = $avg_load + $load;

    }

    $avg_load = $avg_load/SAMPLES;
    $avg_pkt_lat = $avg_pkt_lat/SAMPLES;
    #$max_pkt_lat = $max_pkt_lat/SAMPLES;
    $avg_flit_lat = $avg_flit_lat/SAMPLES;
    #$max_flit_lat = $max_flit_lat/SAMPLES;
    $avg_net_lat = $avg_net_lat/SAMPLES;
    #$max_net_lat = $max_net_lat/SAMPLES;

    print "\nMax Channel Load = ",$avg_load/$in_rate," (",$in_rate,")\n";
    #print "Maximum Max Channel Load = ", $max_load/INJECTION_RATE," (seed=",$max_seed,")\n";
    print "Average Packet Latency = ",$avg_pkt_lat,"\n";
    #print "Max Packet Latency = ",$max_pkt_lat,"\n";
    print "Average Network Latency = ",$avg_net_lat,"\n";
    #print "Max Network Latency = ",$max_net_lat,"\n";;
    print "Average Flit Latency = ",$avg_flit_lat,"\n";
    #print "Max Flit Latency = ",$max_flit_lat,"\n";

    #print DATA $in_rate*64*0.910," ",$avg_load/$in_rate," ",$max_load/$in_rate,"\n";
    #print DATA $in_rate*64*0.910," ",$avg_flit_lat," ",$max_flit_lat,"\n";

#}
close(DATA);
