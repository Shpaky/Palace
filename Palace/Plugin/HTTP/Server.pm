#!/usr/bin/perl

	package Palace::Plugin::HTTP::Server;
	use base 'Palace::Plugin::HTTP';
	use lib './Server';
	use 5.12.0;

	
	sub protocol
	{
		my ( $self ) = @_;

		ref($self).$self->env()->{'HTTP'};
	}

	sub test_http_common_server
	{
		say 'Common method for HTTP Server';
	}
	1;
