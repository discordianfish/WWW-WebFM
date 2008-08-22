#!/usr/bin/perl -w
use strict;
use lib '/data/Code/projects/CGI-Application-WebFM/trunk/lib';
use CGI::Application::WebFM;
#use File::ShareDir;

my $templates = "$INC[0]/../templates"; #File::ShareDir::module_dir('CGI::Application::WebFM');
my $webapp = CGI::Application::WebFM->new
(
	TMPL_PATH => $templates
);
$webapp->run();
