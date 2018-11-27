#!/usr/bin/perl

	package Palace::Plugin::HTTP::Server::FastCGI;
	use base 'Palace::Plugin::HTTP::Server';
	use 5.10.0;


	sub test_http
	{
		say 'Test FastCGI module';
	}
	1;
