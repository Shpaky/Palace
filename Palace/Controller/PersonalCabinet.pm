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

	sub start_page
	{
		my ( $self ) = @_;
		
		$self->tools(
		[
			'init_log',
		]);
		&init_log($self->config()->{'logs'});

		$log->info('|'.$$.'|'.'Begin perform \''.(caller(0))[3].'\' route.');

		my $env = $self->env();
		$self->plugin();

		my $app_dir = $self->env()->{'env'}->{'PWD'};

		print "Content-Type: text/html\r\n\r\n";
		print "<html> <head>\n";
		print "<title>Me managed!</title>";
		print "</head>\n";
		print "<body>\n";
		print "<h3>start page</h3>";
		print "<h3>Perform ".(caller(0))[3]."</h3>";
		print "</body> </html>\n";

		$log->info('|'.$$.'|'.'End perform \''.(caller(0))[3].'\' route.');
	}

	sub authorization
	{
		my ( $self ) = @_;

		$self->tools(
		[
			'init_log',
		]);
		&init_log($self->config()->{'logs'});

		$log->info('|'.$$.'|'.'Begin perform \''.(caller(0))[3].'\' route.');
		
		$self->plugin();
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
		say Data::Dumper->Dump([$self],['self']);

		say Data::Dumper->Dump([$self->env()],['env']);
		say '<br>';
		say Data::Dumper->Dump([$self->connect_plugin('HTTP::Server')->set_data({'Dynamo'=>'Moscow'})],['Object']);
		say '<br>';
		say Data::Dumper->Dump([$self->connect_plugin('HTTP::Server')->set_data({'Dynamo'=>'Moscow'})->test_http_common_http()],['Object']);
		say '<br>';
		say Data::Dumper->Dump([$self->connect_plugin('HTTP::Server')->set_data({'Dynamo'=>'Moscow'})->test_http_common_server()],['Object']);
		say '<br>';
		say Data::Dumper->Dump([$self->connect_plugin('HTTP::Server')->set_data({'Dynamo'=>'Moscow'})->test_http()],['Object']);

		$log->info('|'.$$.'|'.'End perform \''.(caller(0))[3].'\' route.');
	}

	sub registration
	{
		my ( $self ) = @_;
		
		$self->tools(
		[
			'init_log',
		]);
		&init_log($self->config()->{'logs'});

		$log->info('|'.$$.'|'.'Begin perform \''.(caller(0))[3].'\' route.');

		$self->plugin();
		my $env = $self->env();

		my $app_dir = $self->env()->{'env'}->{'PWD'};

		print "Content-Type: text/html\r\n\r\n";
		print "<html> <head>\n";
		print "<title>Me managed!</title>";
		print "</head>\n";
		print "<body>\n";
		print "<h3>Perform ".(caller(0))[3]."</h3>";
		print "</body> </html>\n";

		$log->info('|'.$$.'|'.'End perform \''.(caller(0))[3].'\' route.');
	}

	sub get_info
	{
		my ( $self ) = @_;

		$self->tools(
		[
			'init_log',
			'caller_info',
		]);
		&init_log($self->config()->{'logs'});


		## forming message text log need replace to 'Dictionary' plugin
		$self->config()->{'mode'} eq 'debug'
		? $log->info('|'.$$.'|'.'Begin perform \''.&caller_info($self->config()->{'level_nest'}).'\' route.')
		: $log->info('|'.$$.'|'.'Begin perform \''.(caller(0))[3].'\' route.');

		$self->plugin();
		my $env = $self->env();

		my $app_dir = $self->env()->{'env'}->{'PWD'};

		print "Content-Type: text/html\r\n\r\n";
		print "<html> <head>\n";
		print "<title>Me managed!</title>";
		print "</head>\n";
		print "<body>\n";
		print "<h3>Perform ".(caller(0))[3]."</h3>";
		print "</body> </html>\n";

		$self->config()->{'mode'} eq 'debug'
		? $log->info('|'.$$.'|'.'End perform \''.&caller_info($self->config()->{'level_nest'}).'\' route.')
		: $log->info('|'.$$.'|'.'End perform \''.(caller(0))[3].'\' route.')
	}

	sub set_info
	{
		my ( $self ) = @_;

		$self->tools(
		[
			'init_log',
		]);
		&init_log($self->config()->{'logs'});

		$log->info('|'.$$.'|'.'Begin perform \''.(caller(0))[3].'\' route.');

		$self->plugin();
		my $env = $self->env();

		my $app_dir = $self->env()->{'env'}->{'PWD'};

		print "Content-Type: text/html\r\n\r\n";
		print "<html> <head>\n";
		print "<title>Me managed!</title>";
		print "</head>\n";
		print "<body>\n";
		print "<h3>Perform ".(caller(0))[3]."</h3>";
		print "</body> </html>\n";

		$log->info('|'.$$.'|'.'End perform \''.(caller(0))[3].'\' route.');
	}
	1;
