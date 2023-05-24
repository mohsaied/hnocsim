#!/usr/local/bin/perl
use strict;
use warnings;

my $HNOCSIM_DIR = "/home/andrew/Dropbox/MASc/hnocsim";
my $DESIGN_DIR = "$HNOCSIM_DIR/designs/pkt_parser";

if (@ARGV < 2) {

    print "Usage: perl packet_gen.pl <num_src> <num_pkts>\n";
    exit 0;

}

my ($num_src, $num_pkts) = @ARGV;

for (my $i=0; $i<$num_src; $i++) {

    system("python $DESIGN_DIR/pcap_gen.py $DESIGN_DIR/src$i.pcap $num_pkts");

}
