#!/usr/local/bin/perl

#$cmd_get = '/usr/local/bin/wget -m -np --wait 1 -A "*.[Hh][Tt][Mm][Ll],*.[Ss][Hh][Tt][Mm][Ll],*.[Hh][Tt][Mm]"';
$cmd_get = '/usr/local/bin/wget -m -np -t 1 -A "*.[Hh][Tt][Mm][Ll],*.[Ss][Hh][Tt][Mm][Ll],*.[Hh][Tt][Mm]"';

$url = shift || die "usage: $0 url\n";
$file_tmp = "/tmp/get_html.$$";
$url2 = $url;
$url2 =~ s/\//_/g;
$file_log = "logs/$url2.log";
$args = join(' ', @ARGV);

system "$cmd_get $args http://$url -o $file_tmp";

open(IN, "$file_tmp") || die;
open(OUT, "> $file_log.new") || die;
while (<IN>) {
    s/[\r\n]+$//;
    next unless (s/^           \=\> \`|\'$//g);
    print OUT $_, "\n";
}
close(OUT);
close(IN);

unlink $file_tmp;
rename("$file_log.new", $file_log);

exit 0;
