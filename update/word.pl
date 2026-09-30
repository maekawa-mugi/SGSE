#!/usr/local/bin/perl
#
# 指定したファイル名を語句に分ける
# title, description, keyword も抽出する
#
# 出力フォーマット
#
#        title (Base64)
#        description (Base64)
#        keyword (Base64)
#        title 語句分けしたもの
#        description 語句分けしたもの
#        keyword 語句分けしたもの
#        本文を語句分けしたもの
#
# 使い方
#        word.pl filename
#

require './config.pl';
use MIME::Base64;

# 一時ファイル
$file_tmp = "/tmp/word.$$";

# 使う変数
undef $filename;		# ファイル名
undef $kubun;			# ファイルの区分
undef $lang;			# 言語
undef $in;			# ファイルの内容
undef $title;			# タイトル
undef $description;		# デスクリプション
undef $keyword;			# キーワード
undef $honbun;			# 本文
undef $title_s;			# 特殊キャラクターを処理したもの
undef $description_s;		# 特殊キャラクターを処理したもの
undef $keyword_s;		# 特殊キャラクターを処理したもの
undef $honbun_s;		# 特殊キャラクターを処理したもの
undef @title_word;		# タイトル語句分け後
undef @description_word;	# デスクリプション語句分け後
undef @keyword_word;		# キーワード語句分け後
undef @honbun_word;		# 本文語句分け後

# 引数よりファイル名を抜き出す
$filename = shift || die "usage* $0 filename\n";

# ファイルの区分を判定
if ($filename =~ /\.(shtml|html|htm)$/i) {
    $kubun = 'html';
}

# ファイルの中身を読み出す
# 日本語のコードは EUC にする
# 改行コードの違いもここで吸収する
# X0208 アルファベットは ASCII にする
{
    undef $/;
    local($s) = '';
    die "Can't open $filename" unless (-r $filename);
    open(IN, "$cmd_nkf -Zme \"$filename\" |") || die "Can't exec $cmd_nkf";
    while (<IN>) {
	$s .= $_;
    }
    close(IN);
    $in = join("\n", split(/\r\n|\n|\r/, $s));
}

# 対象ファイルが HTML のとき
if ($kubun eq 'html') {

    # title を抽出する
    if ($in =~ s/\<\s*title\s*\>([^\<]*)\<\s*\/title\s*\>//i) {
	$title = $1;
    } 

    # タグで分ける
    local(@s) = split(/\</, $in);
    grep(s/^/\</, @s[1..$#s]);

    local($s, $in_title, $in_honbun);
    undef $in_title;
    $in_honbun = 1;

    foreach $s (@s) {

	# description を抽出する
	if ($s =~ /^\<\s*meta\s+name\s*\=\s*[\"]*description[\"]*\s+content\s*\=\s*[\"]*([^\"\>]*)/i) {
	    if (defined($description)) {
		$description .= "\n".$1;
	    } else {
		$description = $1;
	    }
	}

	# keyword を抽出する
	if ($s =~ /^\<\s*meta\s+name\s*\=\s*[\"]*keywords[\"]*\s+content\s*\=\s*[\"]*([^\"\>]*)/i) {
	    if (defined($keyword)) {
		$keyword .= "\n".$1;
	    } else {
		$keyword = $1;
	    }
	}

	# <!-- begin header --> 〜 <!-- end header -->
	# <!-- begin footer --> 〜 <!-- end footer -->
	# をヘッダー/フッターと見なし、本文から削除する
	if ($s =~ /^\<\!\-\-\s*begin\s+header\s*\-\-\>/i) {
	    $in_honbun = 0;
	} elsif ($s =~ /^\<\!\-\-\s*end\s+header\s*\-\-\>/i) {
	    $in_honbun = 1;
	} elsif ($s =~ /^\<\!\-\-\s*begin\s+footer\s*\-\-\>/i) {
	    $in_honbun = 0;
	} elsif ($s =~ /^\<\!\-\-\s*end\s+footer\s*\-\-\>/i) {
	    $in_honbun = 1;
	}
	$honbun .= $s if ($in_honbun);
    }

    # 本文からHTMLタグを削除する
    $honbun =~ s/\<[^\>]*\>//g;

} else {

    # 本文を抽出する
    $honbun = $in;
}

# 英語ページかどうかを判定
if ($honbun.$title.$description.$keyword =~ /[\241-\376]/) {
    $lang = 'j';
} else {
    $lang = 'e';
}

$title_s = $title;
$description_s = $description;
$keyword_s = $keyword;
$honbun_s = $honbun;

# アルファベット大文字を小文字にする
$title_s =~ tr/A-Z/a-z/;
$description_s =~ tr/A-Z/a-z/;
$keyword_s =~ tr/A-Z/a-z/;
$honbun_s =~ tr/A-Z/a-z/;

# 特殊なキャラクターを削る
if ($lang eq 'j') {
    $title_s =~ s/[^\241-\376a-z0-9\&\;\#\-\n]+/ /g;
    $description_s =~ s/[^\241-\376a-z0-9\&\;\#\-\n]+/ /g;
    $keyword_s =~ s/[^\241-\376a-z0-9\&\;\#\-\n]+/ /g;
    $honbun_s =~ s/[^\241-\376a-z0-9\&\;\#\-\n]+/ /g;
} else {
    $title_s =~ s/[^a-z0-9\&\;\#\-\n]+/ /g;
    $description_s =~ s/[^a-z0-9\&\;\#\-\n]+/ /g;
    $keyword_s =~ s/[^a-z0-9\&\;\#\-\n]+/ /g;
    $honbun_s =~ s/[^a-z0-9\&\;\#\-\n]+/ /g;
}

# 語句に分ける
if ($lang eq 'j') {
    open(OUT, "> $file_tmp") || die "Can't open $file_tmp";
    print OUT $title_s."\n";
    print OUT "%\n";
    print OUT $description_s."\n";
    print OUT "%\n";
    print OUT $keyword_s."\n";
    print OUT "%\n";
    print OUT $honbun_s."\n";
    print OUT "%\n";
    close(OUT);
    open(IN, "$cmd_chasen -F \"%m \" $file_tmp |")
	|| die "Can't exec $cmd_chasen";
    $/ = '%';
    $title_s = <IN>;
    $title_s =~ s/\%$//;
    $description_s = <IN>;
    $description_s =~ s/\%$//;
    $keyword_s = <IN>;
    $keyword_s =~ s/\%$//;
    $honbun_s = <IN>;
    $honbun_s =~ s/\%$//;
    close(IN);
    unlink $file_tmp;

    # 全角の空白は除く
    $title_s =~ s/ \241\241//g;
    $description_s =~ s/ \241\241//g;
    $keyword_s =~ s/ \241\241//g;
    $honbun_s =~ s/ \241\241//g;
}

# 両側のスペースを削る
$title_s =~ s/^\s+|\s+$//g;
$description_s =~ s/^\s+|\s+$//g;
$keyword_s =~ s/^\s+|\s+$//g;
$honbun_s =~ s/^\s+|\s+$//g;
    
@title_word = split(/[\s\n]+/, $title_s);
@description_word = split(/[\s\n]+/, $description_s);
@keyword_word = split(/[\s\n]+/, $keyword_s);
@honbun_word = split(/[\s\n]+/, $honbun_s);

# 出力する
print join("\t",
	   &encode_base64($title, ''),
	   &encode_base64($description, ''),
	   &encode_base64($keyword, ''),
	   join(' ', @title_word),
	   join(' ', @description_word),
	   join(' ', @keyword_word),
	   join(' ', @honbun_word))."\n";

exit 0;
