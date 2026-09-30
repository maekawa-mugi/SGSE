#!/usr/local/bin/perl

require './config.pl';

use MD5;
$md5 = new MD5;

# 対象ファイルの digest を読み込む

undef %digest;
open(SRC, $file_src) || die "Can't open $file_src";
while ($f = <SRC>) {
    $f =~ s/[\r\n]+$//;
    open(IN, $f) || next;
    $md5->reset();
    $md5->addfile(IN);
    $digest{$f} = $md5->hexdigest();
    close(IN);
}
close(SRC);

open(OUT, "> $file_word_new") || die "Can't open $file_word_new";

# いままでの HTML.word の digest を見て、
# 差がなければ今までの HTML.word の内容を出力する。
if (open(WORD, $file_word)) {
    while (<WORD>) {
	s/[\r\n]+$//;
	undef @s;
	@s = split(/\t/, $_, 3);
	if ($s[1] eq $digest{$s[0]}) {
	    print OUT $_."\n";
	    delete $digest{$s[0]};
	} 
    }
    close(WORD);
}

# いままでの HTML.word にないものは新しく word を作り直す
while (($file, $digest) = each %digest) {
    undef $in;
    next unless (-r $file);

    # mtime を求める
    undef @stat;
    @stat = stat($file);
    $mtime = $stat[9];

    open(IN, "./word.pl \"$file\" |") || die "Can't exec ./word.pl";
    $in = <IN>;
    close(IN);
    next unless ($in =~ /\S/);
    $in =~ s/[\r\n]+$//;
    print OUT join("\t", $file, $digest, $mtime, $in)."\n";
}

close(OUT);

exit 0;
