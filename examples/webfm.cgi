#!/usr/bin/perl -w
use strict;
use lib '/data/Code/projects/WWW-WebFM/trunk/lib';
use WWW::WebFM;
#use File::ShareDir;

my $templates = "$INC[0]/../templates"; #File::ShareDir::module_dir('WWW::WebFM');
my $webapp = WWW::WebFM->new
(
	TMPL_PATH => $templates
);
$webapp->run();
