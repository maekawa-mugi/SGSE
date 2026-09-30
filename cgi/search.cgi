#!/usr/local/bin/perl

chdir '/usr/local/SYSTEM/Search/sonydrive';

$header_j = [
	     '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">',
	     '<html>',
	     '<head>',
	     '<meta http-equiv="Content-Type" content="text/html;'.
	     'charset=x-euc-jp">',
	     '<title>Search Engine</title>',
	     '</head>',
	     '<body bgcolor="#ffffff">',
	     '<!-- begin header -->',
	     '<!-- end header -->',
	     ];

$header_e = [
	     '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">',
	     '<html>',
	     '<head>',
	     '<meta http-equiv="Content-Type" content="text/html;'.
	     'charset=x-euc-jp">',
	     '<title>Search Engine</title>',
	     '</head>',
	     '<body bgcolor="#ffffff">',
	     '<!-- begin header -->',
	     '<!-- end header -->',
	     ];

$footer_j = [
	     '<!-- begin footer -->',
	     '<!-- end footer -->',
	     '</body>',
	     '</html>',
	     ];

$footer_e = [
	     '<!-- begin footer -->',
	     '<!-- end footer -->',
	     '</body>',
	     '</html>',
	     ];

undef @select;

$cgi_name = 'search.cgi';
$in_strong = '<font color="Red"><b>';
$out_strong = '</b></font>';

require './search.pl';

exit 0;
