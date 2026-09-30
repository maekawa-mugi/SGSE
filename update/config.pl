#!/usr/local/bin/perl

$file_conf = 'CONF';
$file_src = 'HTML.src';
$file_word = 'HTML.word';
$file_word_new = "$file_word.new";
$file_inv = 'HTML.inv';
$file_flist = 'HTML.flist';
$file_dir = 'HTML.dir';
$file_idx = 'HTML.idx';
$file_usedir = 'usedir';
$file_group = 'group';

$cmd_nkf = '/usr/local/bin/nkf';
$cmd_chasen = '/usr/local/bin/chasen';
$cmd_sort = '/usr/bin/sort';

# ファイル名と URL の変換
sub transe {
    local($s) = $_[0];
    return $s if ($s =~ s/^\/usr\/local\/SYSTEM\/mirror\//http\:\/\//);
    return $s;
}

# タイトルはスコア +2
$score_title = 2;

# デスクリプションはスコア +10
$score_description = 10;

# キーワードはスコア +100
$score_keyword = 100;

# 本文はスコア +1
$score_honbun = 1;

1;
