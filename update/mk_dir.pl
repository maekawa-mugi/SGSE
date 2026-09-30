#!/usr/local/bin/perl

require './config.pl';

undef %group;
if (open(IN, $file_group)) {
    while (<IN>) {
	s/[\r\n]+$//;
	s/\#.*$//;
	next unless (/\S/);
	if (s/^\t//) {
	    $group{$_} = $group;
	} else {
	    $group = $_;
	}
    }
    close(IN);
}

open(IN, $file_flist) || die "Can't open $file_flist";
undef %dir;
$n = 0;
while (<IN>) {
    s/[\r\n]+$//;
    /^([^\t]*)/;
    $dir = $1;
    while ($dir =~ s/\/[^\/]*$//) {
	last if ($dir eq 'http:/');
	if (defined($dir{$dir})) {
	    $dir{$dir} .= ' '.$n;
	} else {
	    $dir{$dir} = $n;
	}
	if (defined($group = $group{$dir})) {
	    if (defined($dir{$group})) {
		$dir{$group} .= ' '.$n;
	    } else {
		$dir{$group} = $n;
	    }
	}
    }
    $n++;
}
close(IN);

open(OUT, "| $cmd_sort > $file_dir") || die "Can't exec $cmd_sort";
while (($k, $v) = each %dir) {
    print OUT join("\t", $k, $v)."\n";
}
close(OUT);

exit 0;
