#!/usr/bin/perl

	package Palace::Plugin::HTTP::Server;
	use base 'Palace::Plugin::HTTP';
	use 5.10.0;

	
	sub protocol
	{
		my ( $self ) = @_;

		ref($self).$self->env()->{'HTTP'};
		return 'HTTP::Server::FastCGI';
	}

	sub test_http_common_server
	{
		say 'Common method for HTTP Server';
	}
	1;
