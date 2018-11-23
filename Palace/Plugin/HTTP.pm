#!/usr/bin/perl

	package Palace::Plugin::HTTP;
	use base 'Palace::Plugin';
	use lib './HTTP';
	use 5.12.0;


	sub test_http_common_for_http
	{
		say 'Commot method for HTTP';
	}
	1;
