#!/usr/bin/perl

	package Palace::Controller::PersonalCabinet;
	use base 'Palace::Controller';
	use FindBin qw|$Bin|;
	use feature qw|state say|;

	use lib $Bin.'/Palace/lib';
	
	use Log::Any::Adapter;
	Log::Any::Adapter->set('+Adapter');
	use Log::Any '$log';

	state $errors;


	sub authorization
	{
		my ( $self ) = @_;
		
		$self->tools(
		[
			'init_log',
		]);

		&init_log($self->config()->{'logs'});
		$self->plugin();

		$log->info('|'.$$.'|'.'Begin perform \'authorization\' route.');

	#	$self->connect_plugin('HTTP::Server')->set_value(
	#	'data' => 'DATA' )->test_http_common_http();
	#	say Data::Dumper->Dump([$self],['self']);
		
		my $env = $self->env();

		my $app_dir = $self->env()->{'env'}->{'PWD'};

		print "Content-Type: text/html\r\n\r\n";
		print "<html> <head>\n";
		print "<title>Me managed!</title>";
		print "</head>\n";
		print "<body>\n";
		print "<h3 style=\"color:#1488c6;\">Djany, me managed settings interaction 'nginx' and my application server!<br>This message response my application interaction with my application server by chain:<br>'client' -> 'nginx' -> 'my application server' -> 'my either application which may be enable on my server'</h3><br><h3 style=\"color:red;display:inline-block;padding-left:50%;\">I love you my dear, with love your gentle bear!</h3>\n";
		print "<div style=\"color:green;\">pid:$$</div>\n";
		print "</body> </html>\n";
		
		$log->info('|'.$$.'|'.'End perform \'authorization\' route.');
	}
	1;
