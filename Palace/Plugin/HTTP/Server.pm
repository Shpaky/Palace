#!/usr/bin/perl

	package Palace::Plugin::HTTP::Server;
	use base 'Palace::Plugin::HTTP';
	use 5.10.0;

	
	sub protocol
	{
		my ( $self ) = @_;

		given( $self->env()->{'GATEWAY_INTERFACE'} )
		{
			when(/CGI/) { return __PACKAGE__.'::FastCGI' }
		}
	}

	sub test_http_common_server
	{
		say 'Common method for HTTP Server';
	}
	1;
