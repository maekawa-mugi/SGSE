#!/usr/local/bin/perl

require './config.pl';

open(IN, $file_flist) || die "Can't open $file_flist";
open(OUT, "> $file_idx") || die "Can't open $file_idx";
$n = tell(IN);
while (<IN>) {
    print OUT pack('L', $n);
    $n = tell(IN);
}
close(IN);
close(OUT);

exit 0;
