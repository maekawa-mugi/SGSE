#!/usr/local/bin/perl

require './config.pl';

$file_tmp = 'inv.tmp';

# 名称ファイルを読み込む
undef %name;
open(IN, $file_conf) || die "Can't open $file_conf";
while (<IN>) {
    s/[\r\n]+$//;
    split(/\t/);
    $name{$_[0]} = $_[1];
}
close(IN);

# taishou directory wo yomikomu
undef %dir_use;
undef %dir_notuse;
undef $dir_use;
if (open(IN, $file_usedir)) {
    $dir_use = 1;
    while (<IN>) {
	s/[\r\n]+$//;
	if (/^\!/) {
	    $dir_notuse{$_}++;
	} else {
	    $dir_use{$_}++;
	}
    }
    close(IN);
    
}

undef %score;

open(FLIST, "> $file_flist") || die "Can't open $file_flist";
open(TMP, "> $file_tmp") || die "Can't open $file_tmp";
open(IN, $file_word) || die "Can't open $file_word";
$n = 0;
while (<IN>) {
    s/[\r\n]+$//;
    undef @s;
    @s = split(/\t/);

    # taisho directory ka douka no hantei
    if (defined($dir_use)) {
	local($d) = $s[0];
	local($ok) = 0;
	while (1) {
	    last if (defined($dir_notuse{$d}));
	    if (defined($dir_use{$d})) {
		$ok = 1;
		last;
	    }
	    last unless ($d =~ s/\/[^\/]*$//);
	}
	next if ($ok == 0);
    }

    @title = split(/\s+/, $s[6]);
    @description = split(/\s+/, $s[7]);
    @keyword = split(/\s+/, $s[8]);
    @honbun = split(/\s+/, $s[9]);

    $url = &transe($s[0]);

    # 名称を求める
    undef $name;
    local($u) = $url;
    while (1) {
	last if (defined($name = $name{$u}));
	last unless ($u =~ s/\/[^\/]*$//);
    }

    # HTML.flist に出力する
    print FLIST join("\t",
		     $url,	# URL
		     $s[1],	# md5
		     $s[2],	# mtime
		     $name,	# 名称
		     $s[3],	# title (Base64)
		     $s[4],	# description (Base64)
		     $s[5],	# keyword (Base64)
		     join(' ', @honbun[0..($#honbun < 30 ? $#honbun : 29)]),
		     )."\n";

    # タイトル
    foreach $w (@title) {
	&add_score($w, $n, $score_title);
    }

    # デスクリプション
    foreach $w (@description) {
	&add_score($w, $n, $score_description);
    }

    # キーワード
    foreach $w (@keyword) {
	&add_score($w, $n, $score_keyword);
    }

    # 本文
    foreach $w (@honbun) {
	&add_score($w, $n, $score_honbun);
    }

    if ($n % 1000 == 0) {
	while (($k, $v) = each %score) {
	    print TMP $k;
	    foreach $kk (sort {$a <=> $b} keys %$v) {
		printf(TMP "\t%s %s", $kk, $$v{$kk});
	    }
	    print TMP "\n";
	}
	undef %score;
    }

    $n++;
}
close(IN);
close(FLIST);

while (($k, $v) = each %score) {
    print TMP $k;
    foreach $kk (sort {$a <=> $b} keys %$v) {
	printf(TMP "\t%s %s", $kk, $$v{$kk});
    }
    print TMP "\n";
}

close(TMP);

undef %score;

# テンポラリファイルをマージして HTML.inv を作る
open(OUT, "> $file_inv") || die "Can't open $file_inv";
mkdir('tmp', 0755) unless (-d 'tmp');
open(IN, "$cmd_sort -T tmp $file_tmp |") || die "Can't exec $cmd_sort";
undef @out;
while (<IN>) {
    s/[\r\n]+$//;
    undef $s;
    ($w, $s) = split(/\t/, $_, 2);
    if ($w ne $word) {
	print OUT join("\t", $word, @out)."\n";
	undef @out;
    }
    push(@out, $s);
    $word = $w;
}
print OUT join("\t", $word, @out)."\n";
close(IN);
close(OUT);

unlink($file_tmp);

exit 0;

sub add_score {
    local($w, $n, $p) = @_;

    # 両側のハイフンを削る
    $w =~ s/^\-+|\-+$//g;

    $score{$w} = {} unless (defined($score{$w}));
    ${$score{$w}}{$n} += $p;

    if ($w =~ /\-/) {
	local($ww);

	# 語句にハイフンが入っているものは、
        # ハイフンを除いたものを検索対象に加える
	$ww = $w;
	$ww =~ s/\-//g;
	if ($ww =~ /\S/) {
	    $score{$ww} = {} unless (defined($score{$ww}));
	    ${$score{$ww}}{$n} += $p;
	}
	
	# ハイフンで分けたものも検索対象とする
	foreach $ww (split(/\-/, $w)) {

	    next unless ($ww =~ /\S/);

	    $score{$ww} = {} unless (defined($score{$ww}));
	    ${$score{$ww}}{$n} += $p;
	}
    }
}
