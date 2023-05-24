#!/usr/local/bin/perl
use strict;
use warnings;

open my $file, 'trace.out' or die "Failed\n";

my $flat_max = 0;

while (my $line = <$file>) {

    if ($line =~ /^(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*(\d+)$/) {
	my $id = $1;
	my $src = $2;
	my $dest = $3;
	my $hops = $4;
	my $flat = $5;

	if ($src > 15) {
	    $src = $src - 48;
	}
	if ($dest > 15) {
	    $dest = $dest - 48;
	}

	if ($flat > $flat_max) {
	    $flat_max = $flat;
	}

#	print "$id\t$src\t$dest\t$hops\t$flat\n";

	my $h = abs($src - $dest) + 1;

	if (($src<8 && $dest>7) || ($src>7 && $dest<8)) {
	    if ($src > $dest) {
		$h = abs($dest - ($src - 8)) + 8;
	    }
	    else {
		$h = abs($src - ($dest - 8)) + 8;
	    }
	}
	
	if ($hops != $h) {
	    print "Hops error: ID = $id ($hops vs $h)\n";
	}

    }

}

print $flat_max,"\n";
print "Done\n";

