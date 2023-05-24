#!/usr/local/bin/perl
use strict;
use warnings;

use constant SEED => 15801;
use constant SAMPLES => 40;
use constant INJECTION_RATE => 0.172;

srand(SEED);

open my $file, 'switch_config' or die "Failed\n";

my $in_rate = -1;
while (my $line = <$file>) {
    if ($line =~ /^injection_rate\s*=\s*([0-9]*\.?[0-9]*);/) {
	$in_rate = $1;
    }
}

my $avg_load = 0;
my $max_seed;
my $avg_pkt_lat = 0;
my $avg_flit_lat = 0;
my $avg_net_lat = 0;
my $sim_out;

for (my $i=0; $i<SAMPLES; $i++) {
    #print int(rand(10000)),"\n";

    my $seed = int(rand(1000000000));
    my $result = `/home/andrew/booksim2-master/src/booksim switch_config sample_period=10000 perm_seed=$seed`;

    my $temp_pkt_lat;
    
    while ($result =~ /Packet latency average = ([0-9]*\.?[0-9]*) \(1 samples\).*\n.*minimum = \d+ \(1 samples\).*\n.*maximum = (\d+)/g) {
	$temp_pkt_lat = $1;
    }
    
    if ($temp_pkt_lat > $avg_pkt_lat) {

	$avg_pkt_lat = $temp_pkt_lat;

	$sim_out = $result;

	$max_seed = $seed;

	my $max_activity;
	while ($result =~ /Max channel activity = (\d+) cycles/g) {
	    $max_activity = $1
	}	

	while ($result =~ /Flit latency average = ([0-9]*\.?[0-9]*) \(1 samples\).*\n.*minimum = \d+ \(1 samples\).*\n.*maximum = (\d+)/g) {
	    $avg_flit_lat = $1;
	}
	
	while ($result =~ /Network latency average = ([0-9]*\.?[0-9]*) \(1 samples\).*\n.*minimum = \d+ \(1 samples\).*\n.*maximum = (\d+)/g) {
	    $avg_net_lat = $1;
	}
	
	my $tot_cycles = 0;
	while ($result =~ /Time taken is (\d+) cycles/g) {
	    $tot_cycles = $1;
	}

	if ($tot_cycles == 0) {
	    print $result;
	    print "\nFailed with seed = ",$seed,"\n";
	}

	$avg_load = $max_activity/$tot_cycles;

    }

}

if ($sim_out =~ /Begin Route Table([\S\s]*)End Route Table/) {
    print $1;
}

print "\nMax Channel Load = ",$avg_load/$in_rate," (",$in_rate,")\n";
#print "Maximum Max Channel Load = ", $max_load/INJECTION_RATE," (seed=",$max_seed,")\n";
print "Average Packet Latency = ",$avg_pkt_lat,"\n";
#print "Max Packet Latency = ",$max_pkt_lat,"\n";
print "Average Network Latency = ",$avg_net_lat,"\n";
#print "Max Network Latency = ",$max_net_lat,"\n";;
print "Average Flit Latency = ",$avg_flit_lat,"\n";
#print "Max Flit Latency = ",$max_flit_lat,"\n";
print "(SEED = ", $max_seed, ")\n";
