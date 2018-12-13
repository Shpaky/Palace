#!/usr/bin/perl

	package Palace::Plugin::HTTP::Server::FastCGI;
	use base 'Palace::Plugin::HTTP::Server';
	use 5.10.0;


	sub test_http
	{
		say 'Test FastCGI module';
	}

	sub url
	{
		my ( $self ) = @_;

		$self->env()->{'URI'};
	}

	sub request_url
	{
		my ( $self ) = @_;

		$self->env()->{'REQUEST_URI'};
	}

	sub request_method
	{
		my ( $self ) = @_;

		$self->env()->{'REQUEST_METHOD'};
	}

	sub server_port
	{
		my ( $self ) = @_;

		$self->env()->{'SERVER_PORT'};
	}

	sub remote_port
	{
		my ( $self ) = @_;

		$self->env()->{'REMOTE_PORT'};
	}

	sub remote_address
	{
		my ( $self ) = @_;

		$self->env()->{'REMOTE_ADDR'};
	}

	sub query_string
	{
		my ( $self ) = @_;

		$self->env()->{'QUERY_STRING'};
	}

	sub request_scheme
	{
		my ( $self ) = @_;

		$self->env()->{'REQUEST_SCHEME'};
	}

	1;
