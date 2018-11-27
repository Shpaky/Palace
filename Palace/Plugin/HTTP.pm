#!/usr/bin/perl

	package Palace::Plugin::HTTP;
	use base 'Palace::Plugin';
	use 5.10.0;


	sub protocol
	{
		my ( $self ) = @_;

		ref($self).$self->env()->{'HTTP'};
		return 'HTTP::Server';
	}

	sub test_http_common_http
	{
		say 'Commot method for HTTP';
	}
	1;
