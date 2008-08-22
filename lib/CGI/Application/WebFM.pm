package CGI::Application::WebFM;

use CGI::Application;
use Encode;
use strict;
use warnings;
use base ("CGI::Application::Plugin::HTCompiled", "CGI::Application");

our $VERSION = '0.01';

sub setup
{
	my $self = shift;
	$self->{commands} =
	{
		'play' => 2,
		'info' => 2,
		'love' => 1,
		'ban' => 1,
		'skip' => 1,
		'pause' => 1,
		'stop' => 1,
	};

	$self->{formatf} = 
	{
                'artist' => '%a',
                'title' => '%t',
                'album' => '%l',
                'duration' => '%d',
                'name-station' => '%s',
                'url-station' => '%S',
                'url-artist' => '%A',
                'url-albums' => '%L',
                'url-tracks' => '%T',
                'remain' => '%R',

	};

	$self->{urlf} =
	{
		'user_personal' => 'lastfm://user/%s/personal',
		'user_playlist' => 'lastfm://user/%s/playlist',
		'user_neighbours' => 'lastfm://user/%s/neighbours',
		'user_recommended' => 'lastfm://user/%s/recommended/100',
		'artist' => 'lastfm://artist/%s/similarartists',
		'tag' => 'lastfm://globaltags/%s',
		'group' => 'lastfm://group/%s',
	};

	$self->run_modes
	(
		'action' => 'action',
		'index' => 'view_index',
		'error' => 'view_error',
	);

	$self->start_mode('index');
	$self->error_mode('view_error');

	$self->query->charset('utf8');
}

sub view_index
{
	my $self = shift;
	my $status = shift || '';

	# FIXME: wegen kollisionen eventuell einen anderen seperator waehlen
	my %info = %{ $self->{formatf} };
	my @keys = keys %info;
	my $state_old = $self->query->param('state');
	my $i;
	foreach (split /\|/, $self->shellfm('info', join '|', values %info))
	{
		$info{$keys[$i++]} = $_;
	}
	return $self->render_index($status, \%info);
}

sub render_index
{
	my $self = shift;
	my $status = shift;
	my $info = shift || '';
	my $t = $self->load_tmpl('index.tmpl', die_on_bad_params=>0, global_vars=>1);
	$t->param(STATUS=>$status, INFO=>$info);

	return $t->output;
}

sub view_error
{
	my $self = shift;
	my $error = shift;
	return $self->render_index($error);
}
sub spawnshellfm
{
	my $self = shift;
	$ENV{HOME}=$self->param('home') || '/var/www/';
	system('shell-fm -i localhost -d > /dev/null 2>&1')  == 0 or die "could not spawn shell-fm";
	warn "done spawning shell-fm";
	#FIXME: pruefen ob der erfolgreich in background forkt - wenn nicht (z.b keine konfig) --> killen
	#die "Error spawning shell-fm: '$ret'" if $ret;
	return
}
sub shellfm
{
	my $self = shift;
	my $action = shift;
	die "invalid action" unless $self->{commands}->{$action};
	my $param = shift || '';

	my $host = $self->param('host') || 'localhost';
	my $port = $self->param('port') || 54311;

	
	warn "connecting to $host:$port and sending $action $param";
	use IO::Socket::INET;

	my %opt = (
		PeerAddr => $host,
		PeerPort => $port,
		Proto => 'tcp'
	);
	my $c = IO::Socket::INET->new(%opt);
	unless ($c)
	{
		warn "could not connect to $host:$port '$@ / $!'.. trying spawning shell-fm..";
		$self->spawnshellfm;
		$c = IO::Socket::INET->new(%opt);
	}
	die "\tconnection still failed" unless $c;
	$c->autoflush(1);


	print $c $self->{commands}->{$action} > 1 ? "$action $param" : $action, "\n";
	
	$/='';
	$_ = <$c>; #encode 'iso-8859-1', decode 'utf8', <$c>;
	close $c;
	warn "returned: $_";

	die $_ if $_ and $_ =~ /^ERROR/;

	return $_;
}

sub play
{
	my $self = shift;
	my $param = shift;
	my $type = $self->query->param('type') || 'url';
	my $url;

	unless ($type eq 'url')
	{
		my $fs = $self->{urlf}->{$type};
		die "invalid type" unless $fs;

		$url = sprintf $fs, $param;
		warn "type: $type, fs: $fs, url: $url";
	} else
	{
		$url = $param;
	}
	return $self->shellfm('play', $url);
}

sub action
{
	my $self = shift;
	my $action = $self->query->param('action');

	my $param = $self->query->param('param') || '';
	warn "action: $action";

	my $ret = $action eq 'play' ? $self->play($param) : $self->shellfm($action,$param);

	#TODO: wait until state_old != state or so one
	$self->header_type('redirect');
	$self->header_props(-url => $ENV{SCRIPT_NAME});
	return $ret;
}
