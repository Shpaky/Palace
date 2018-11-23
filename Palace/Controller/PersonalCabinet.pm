#!/usr/bin/perl

	package Palace::Controller::PersonalCabinet;
	use base 'Palace::Controller';
	use File::Glob qw|bsd_glob|;
	use FindBin qw|$Bin|;
	use feature qw|state say|;

	use lib $Bin.'/Palace/lib';
	
	use Log::Any::Adapter;
	Log::Any::Adapter->set('+Adapter');
	use Log::Any '$log';

	state $errors;


	sub authorization
	{
		1;
	}
