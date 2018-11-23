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

		$log->info('|'.$$.'|'.'Begin perform \'authorization\' route.');

		$self->plugin();
		
		my $env = $self->env();

		my $app_dir = $self->env()->{'env'}->{'PWD'};

		
		$log->info('|'.$$.'|'.'End perform \'authorization\' route.');
	}
	1;
