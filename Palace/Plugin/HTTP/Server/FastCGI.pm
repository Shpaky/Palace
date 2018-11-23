#!/usr/bin/perl

	package Palace::Plugin::HTTP::Server::FsstCGI;
	use base 'Palace::Plugin::HTTP::Server';
	use 5.12.0;


	sub test_http
	{
		say 'FastCGI';
	}
	1;
