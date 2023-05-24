#!/usr/local/bin/perl

open(DATA, ">switch_mesh8x8") or die "Failed.";

for ($i=0; $i<64; $i++) {
    print DATA "router ",$i;
    if ($i%8 != 7) {
	print DATA " router ",$i+1;
    }
    if ($i < 56) {
	print DATA " router ",$i+8;
    }
    if ($i<8) {
	print DATA " node ",$i;
    }
    if ($i > 55) {
	print DATA " node ",$i-48;
    }
    print DATA "\n";
}

close DATA;

open(DATA, ">switch_mesh8x2") or die "Failed.";

for ($i=0; $i<16; $i++) {
    print DATA "router ",$i;
    if ($i%8 != 7) {
	print DATA " router ",$i+1;
    }
    if ($i<8) {
	print DATA " router ",$i+8;
    }
    print DATA " node ",$i;
    print DATA "\n";
}

close DATA;

open(DATA, ">switch_mesh4x4") or die "Failed.";

for ($i=0; $i<16; $i++) {
    print DATA "router ",$i;
    if ($i%4 != 3) {
	print DATA " router ",$i+1;
    }
    if ($i < 12) {
	print DATA " router ",$i+4;
    }
    if ($i < 4) {
	print DATA " node ",$i*2," node ",$i*2+1;
    }
    if ($i > 11) {
	print DATA " node ",($i-11)*2+6," node ",($i-11)*2+7;
    }
    print DATA "\n";
}
close DATA;

open(DATA, ">switch_mesh4x2") or die "Failed.";

for ($i=0; $i<8; $i++) {
    print DATA "router ",$i;
    if ($i%4 != 3) {
	print DATA " router ",$i+1;
    }
    if ($i<4) {
	print DATA " router ",$i+4;
    }
    print DATA " node ",$i*2," node ",$i*2+1;
    print DATA "\n";
}
close DATA;
