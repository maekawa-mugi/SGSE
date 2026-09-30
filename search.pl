#!/usr/local/bin/perl

require 'jcode.pl';
require 'look.pl';
use MIME::Base64;

$file_dir = 'HTML.dir';
$file_idx = 'HTML.idx';
$file_inv = 'HTML.inv';
$file_flist = 'HTML.flist';
$file_log = '/usr/local/WWW/search.sony.co.jp/logs/search_log';

@month = (
	  'Jan.', 'Feb.', 'Mar.', 'Apr.', 'May', 'Jun.',
	  'Jul.', 'Aug.', 'Sep.', 'Oct.', 'Nov.','Dec.',
	  );

$file_tmp = "/tmp/search.$$";

$cmd_nkf = '/usr/local/bin/nkf';
$cmd_chasen = '/usr/local/bin/chasen';

$t = &get_input;

$input = $$t{'input'};
$d_input = &kakko($input);
$d_input =~ s/\"/\&quot\;/g;

$url = $$t{'url'};
$lang = $$t{'lang'};
$start = $$t{'start'} + 0;
$referer = $$t{'referer'};
$referer = $ENV{'HTTP_REFERER'} unless ($referer =~ /\S/);
undef $referer unless ($referer =~ /\S/);

if ($$t{'number'} =~ /\S/) {
    $number = $$t{'number'} + 0;
} else {
    $number = 50 unless (defined($number));
}

$number = 1000 if ($number > 1000);

undef $url unless ($url =~ /\S/);

if ($lang =~ /^j/i) {
    $header = $header_j;
    $footer = $footer_j;
} else {
    $header = $header_e;
    $footer = $footer_e;
}

$script = $ENV{'SCRIPT_URL'};
$host = $ENV{'REMOTE_HOST'};
unless ($host =~ /\S/) {
    $host = $ENV{'REMOTE_ADDR'};
}
$user = $ENV{'REMOTE_USER'};
{
    local(@x, $x);
    push(@x, $script, $^T, $referer, $host, $user, $input, $url, $lang, $start);
    grep(s/\t/ /g, @x);
    $x = join("\t", @x);
    $x =~ s/\n/\013/g;
    if (open(LOG, ">> $file_log")) {
	print LOG $x."\n";
	close(LOG);
    }
}

undef @fail;
undef @out;
undef %word;

if (defined($referer)) {
    push(@out, '<blockquote><div align="right">');
    if ($lang =~ /^j/i) {
	push(@out, '<a href="'.$referer.'">もとのページに戻る</a>');
    } else {
	push(@out, '<a href="'.$referer.'">Return</a>');
    }
    push(@out, '</div></blockquote>');
}

unless (open(DIR, $file_dir) && open(INV, $file_inv) &&
	open(FLIST, $file_flist) && open(IDX, $file_idx)) {
    if ($lang =~ /^j/i) {
	push(@fail, '申し訳ありません。');
	push(@fail, '検索システムのエラーにより停止しました。');
    } else {
	push(@fail, 'Sorry, system error.');
    }
    &finish;
}

push(@out, '<form method="post" action="'.$cgi_name.'">');
push(@out, '<input type="hidden" name="lang" value="'.$lang.'">');
if (defined($referer)) {
    push(@out, '<input type="hidden" name="referer" value="'.$referer.'">');
}
if (defined($url) && !defined(@select)) {
    push(@out, '<input type="hidden" name="url" value="'.$url.'">');
}
push(@out, '<pre>');
if ($lang =~ /^j/i) {
    push(@out, '  探したい言葉を入力してください。');
    push(@out, '    => <input type="text" name="input" value="'.
	 $d_input.'" size="50"> <input type="submit" value="検索する">');
    if (defined(@select)) {
	push(@out, '    検索対象コーナーが指定できます => <select name="url">');
	local($s);
	foreach $s (@select) {
	    if ($$s[0] eq $url) {
		push(@out, '<option value="'.$$s[0].'" selected>'.$$s[1]);
	    } else {
		push(@out, '<option value="'.$$s[0].'">'.$$s[1]);
	    }
	}
	push(@out, '</select>');
    }

} else {
    push(@out, '  Please input search word.');
    push(@out, '    => <input type="text" name="input" value="'.
	 $d_input.'" size="50"> <input type="submit" value="Search">');
    if (defined(@select)) {
	push(@out, '    Choose category => <select name="url">');
	local($s);
	foreach $s (@select) {
	    if ($$s[0] eq $url) {
		push(@out, '<option value="'.$$s[0].'" selected>'.$$s[2]);
	    } else {
		push(@out, '<option value="'.$$s[0].'">'.$$s[2]);
	    }
	}
	push(@out, '</select>');
    }
}
push(@out, '</pre>');
push(@out, '</form>');

# 対象 URL 以下のリストを作る
undef %url;
if (defined($url)) {
    seek(DIR, 0, 0);
    &look(DIR, $url."\t");
    while (<DIR>) {
	if (s/^$url\t//) {
	    local($n);
	    foreach $n (split(/\s/)) {
		$url{$n}++;
	    }
	}
	last;
    }
    &not_found unless (defined(%url));
}

# chasen に渡して語句に分ける
if ($input =~ /[\241-\376]/) {
    unless (open(TMP, "> $file_tmp")) {
	if ($lang =~ /^j/i) {
	    push(@fail, '申し訳ありません。');
	    push(@fail, '検索システムのエラーにより停止しました。');
	} else {
	    push(@fail, 'Sorry, system error.');
	}
	&finish;
    }
    print TMP $input."\n";
    close(TMP);
    unless (open(TMP, "$cmd_nkf -Ze $file_tmp | $cmd_chasen -D localhost -F \"%m \" |")) {
	if ($lang =~ /^j/i) {
	    push(@fail, '申し訳ありません。');
	    push(@fail, '検索システムのエラーにより停止しました。');
	} else {
	    push(@fail, 'Sorry, system error.');
	}
	&finish;
    }
    undef $sss;
    while (<TMP>) {
	$sss .= $_;
    }
    close(TMP);
    unlink $file_tmp;
} else {
    $sss = $input;
}

# アルファベット大文字は小文字にする
$sss =~ tr/A-Z/a-z/;

# 特殊なキャラクターをスペースにする
$sss =~ s/[^\241-\376a-z0-9\&\;\#\-\(\)]+/ /g;

# 入力文字列の前後のスペースを削る
$sss =~ s/^\s+|\s+$//g;

# かっこの内側のスペースを削る
$sss =~ s/\(\s+/\(/g;
$sss =~ s/\s+\)/\)/g;

# and, or, not の処理
$sss =~ s/\s+and\s+/\@/ig;
$sss =~ s/\)and\s+/\)\@/ig;
$sss =~ s/\)and\(/\)\@\(/ig;
$sss =~ s/\s+and\(/\@\(/ig;

$sss =~ s/\s+or\s+/\|/ig;
$sss =~ s/\)or\s+/\)\|/ig;
$sss =~ s/\)or\(/\)\|\(/ig;
$sss =~ s/\s+or\(/\|\(/ig;

$sss =~ s/\s+not\s+/\!/ig;
$sss =~ s/\)not\s+/\)\!/ig;
$sss =~ s/\)not\(/\)\!\(/ig;
$sss =~ s/\s+not\(/\!\(/ig;

# スペースを '+' に変換する
$sss =~ s/\s+/\+/g;

$pattern = $sss;
$pattern =~ s/\+/ /g;
$pattern =~ s/\|/ OR /g;
$pattern =~ s/\@/ AND /g;
$pattern =~ s/\!/ NOT /g;

if (defined($url)) {
    push(@out, '  URL            : '.$url);
}
push(@out, '<pre>  Search pattern : '.$pattern);

# 検索する
$match = &expr_space;

# 指定した URL との and をとる
if (defined(%url)) {
    local(%s, $k, $v);
    undef %s;

    while (($k, $v) = each %$match) {
	$s{$k} = $v if (defined($url{$k}));
    }
    &not_found unless (defined(%s));
    $match = \%s;
}

undef @match;
while (($k, $v) = each %$match) {
    local(@x) = ($k, $v);
    push(@match, \@x);
}
&not_found unless (defined(@match));
@match = sort compare @match;

if ($lang =~ /^j/i) {
    push(@out, '  '.($#match + 1).'件見つかりました。</pre>');
} else {
    if ($#match == 0) {
	push(@out, '  1 url found.</pre>');
    } else {
	push(@out, '  '.($#match + 1).' urls found.</pre>');
    }
}

push(@out, '<hr noshade>');
push(@out, '<ol start="'.($start + 1).'">');

print "Content-type: text/html\n\n";
print join("\n", @$header)."\n";
print join("\n", @out)."\n";
undef @out;

for ($i = $start, $n = 0; $n < $number && defined($match[$i]); $i++) {
    local($m) = $match[$i];
    seek(IDX, $$m[0] * 4, 0) || next;
    next unless (read(IDX, $pos, 4) == 4);
    $pos = unpack('L', $pos);
    seek(FLIST, $pos, 0) || next;
    while ($s = <FLIST>) {
	$s =~ s/[\r\n]+$//;
	@flist = split(/\t/, $s);
	if ($lang =~ /^j/i) {
	    local(@t) = localtime($flist[2]);
	    local($date) = sprintf("%04d/%02d/%02d",
				   $t[5] + 1900, $t[4] + 1, $t[3]);
	    push(@out,
		 '<li><nobr><b>'.&kakko($flist[3]).'</b> '.
		 &decode_base64($flist[4]).
		 ' (Score: '.$$m[1].', Update: '.
		 $date.')</nobr><br>');
	} else {
	    local(@t) = gmtime($flist[2]);
	    local($date) =
		join(' ', $month[$t[4]], $t[3].',', $t[5] + 1900);
	    push(@out,
		 '<li><nobr><b>'.&kakko($flist[3]).'</b> '.
		 &decode_base64($flist[4]).
		     ' (Score: '.$$m[1].', Update: '.
		 $date.')</nobr><br>');
	}
	push(@out,
	     '<nobr><tt><a href="'.$flist[0].'">'.
	     $flist[0].'</a></tt></nobr><br>'.
	     '<br>'
	     );
	if ($flist[5] =~ /\S/) {
	    push(@out,
		 '<nobr>'.&decode_base64($flist[5]).'</nobr><br>');
	}
	if ($flist[7] =~ /\S/) {
	    local(@s) = split(/\s/, $flist[7]);
	    local($s);
	    foreach $s (@s) {
		$s = $in_strong.$s.$out_strong if (defined($word{$s}));
	    }
	    push(@out, '<blockquote>');
	    push(@out, join(' ', @s));
	    push(@out, '</blockquote>');
	}
	last;
    }
    print join("\n", @out)."\n";
    undef @out;
    $n++;
}
push(@out, '</ol>');

$start += $number;
if ($start <= $#match + 1) { 
    push(@out, '<blockquote><div align="right">');
    push(@out, '<form method="post" action="'.$cgi_name.'">');
    push(@out, '<input type="hidden" name="lang" value="'.$lang.'">');
    push(@out, '<input type="hidden" name="input" value="'.$d_input.'">');
    push(@out, '<input type="hidden" name="url" value="'.$url.'">') 
	if (defined($url));
    push(@out, '<input type="hidden" name="referer" value="'.$referer.'">')
	if (defined($referer));
    push(@out, '<input type="hidden" name="start" value="'.$start.'">');
    push(@out, '<input type="hidden" name="number" value="'.$number.'">');
    push(@out, '<input type="submit" value="Next '.$number.'"');
    push(@out, '</form>');
    push(@out, '</div></blockquote>');
}

close(DIR);
close(IDX);
close(INV);
close(FLIST);

print join("\n", @out)."\n";
print join("\n", @$footer)."\n";

exit 0;

sub not_found {
    push(@out, '<blockquote>');
    if ($lang =~ /^j/i) {
	push(@out, '見つかりません。');
    } else {
	push(@out, 'Not Found.');
    }
    push(@out, '</blockquote></pre>');
    &finish;
}
		 
sub compare {
    if ($$a[1] == $$b[1]) {
	return $$a[0] <=> $$b[0];
    } else {
	return $$b[1] <=> $$a[1];
    }
}

sub finish {
    if (defined(@fail)) {
	print "Content-type: text/html\n\n";
	print join("\n", @$header)."\n";
	print "<pre>\n";
	print join("\n", @fail)."\n";
	print "</pre>\n";
	print join("\n", @$footer)."\n";
	exit 0;
    }

    print "Content-type: text/html\n\n";
    print join("\n", @$header)."\n";
    print join("\n", @out)."\n";
    print join("\n", @$footer)."\n";

    exit 0;
}

sub get {
    local($p) = @_;
    local($s, $ss, %s);
    undef %s;

    seek(INV, 0, 0);
    &look(INV, $p."\t");
    while ($s = <INV>) {
	if ($s =~ s/$p\t//) {
	    foreach $ss (split(/\t/, $s)) {
		local(@x) = split(/\s/, $ss);
		$s{$x[0]} = $x[1];
	    }
	}
	last;
    }
    return \%s;
}

sub exec_space {
    local($left, $right) = @_;
    local(%s, $k, $v);
    undef %s;

    while (($k, $v) = each %$left) {
	if (defined($$right{$k})) {
	    $s{$k} = &min($v, $$right{$k});
	}
    }
    return \%s;
}

sub min {
    local($a, $b) = @_;
    return ($a <= $b) ? $a : $b;
}

sub exec_or {
    local($left, $right) = @_;
    local(%s, $k, $v);
    undef %s;

    while (($k, $v) = each %$left) {
	$s{$k} = $v;
    }

    while (($k, $v) = each %$right) {
	$s{$k} += $v;
    }

    return \%s;
}

sub exec_and {
    local($left, $right) = @_;
    local(%s, $k, $v);
    undef %s;

    while (($k, $v) = each %$left) {
	if (defined($$right{$k})) {
	    $s{$k} = $v * $$right{$k};
	}
    }
    return \%s;
}

sub exec_not {
    local($left, $right) = @_;
    local(%s, $k, $v);
    undef %s;

    while (($k, $v) = each %$left) {
	unless (defined($$right{$k})) {
	    $s{$k} = $v;
	}
    }
    return \%s;
}

sub expr_space {
    local($left, $right);

    $left = &expr_or;
    while ($sss =~ s/^\+//) {
	$right = &expr_or;
	$left = &exec_space($left, $right);
    }
    return $left;
}

sub expr_or {
    local($left, $right);

    $left = &expr_and;
    while ($sss =~ s/^\|//) {
	$right = &expr_and;
	$left = &exec_or($left, $right);
    }
    return $left;
}

sub expr_and {
    local($left, $right);

    $left = &expr_not;
    while ($sss =~ s/^\@//) {
	$right = &expr_not;
	$left = &exec_and($left, $right);
    }
    return $left;
}

sub expr_not {
    local($left, $right);

    $left = &expr_term;
    while ($sss =~ s/^\!//) {
	$right = &expr_term;
	$left = &exec_not($left, $right);
    }
    return $left;
}

sub expr_term {
    local($val);
    undef $val;

    if ($sss =~ s/^\(//) {
	$val = &expr_space;
	unless ($sss =~ s/^\)\s*//) {
	    if ($lang eq 'j') {
		push(@fail, '右かっこがありません。');
	    } else {
		push(@fail, 'Missing right paren.');
	    }
	    &finish;
	}
    } elsif ($sss =~ s/([^\+\!\@\|\(\)]+)//) {
	$word{$1}++;
	$val = &get($1);
    }
    return $val;
}

sub get_input {
    local(%t, $ss);
    undef %t;

    read(STDIN, $INPUT, $ENV{'CONTENT_LENGTH'})
        if (length($INPUT = $ENV{'QUERY_STRING'}) <= 0);

    foreach $ss (split(/\&/, $INPUT)) {
        local($s1, $s2) = split(/\=/, $ss, 2);
        $s1 =~ s/\+/ /g;
        $s1 =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $s2 =~ s/\+/ /g;
        $s2 =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

        next unless ($s2 =~ /\S/);
	&jcode::convert(*s2, 'euc', undef, 'z');
	$t{$s1} = $s2;
    }
    return \%t;
}

# 文字列に '<', '>', '&' が含まれていたとき、
# それぞれ '&lt;' '&gt;' '&amp;' に変換する。
sub kakko {
    local($s) = $_[0];
    $s =~ s/\&/\&amp\;/g;
    $s =~ s/\</\&lt\;/g;
    $s =~ s/\>/\&gt\;/g;
    return $s;
}
