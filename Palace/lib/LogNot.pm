#!/usr/lib/perl

	package LogNot;

	use Log::Log4perl qw(get_logger :levels);
	use Data::Dumper;
	use CONFIG;

	sub new 
	{ 
		my $class = shift if $_[0] eq __PACKAGE__ || ref($_[0]) eq __PACKAGE__;
		my $self  = $_[0] ? shift : {};

		Log::Log4perl->init($CONFIG::path->{'conf_log'});
	
		bless $self, $class;
		
		return $self;
	} 

	Log::Log4perl->init($CONFIG::path->{'conf_log'});

	sub log_info 
	{ 	
		my $self = shift if $_[0] eq __PACKAGE__ || ref($_[0]) eq __PACKAGE__;
		my $text = shift;
		my $data = shift;
		
		my $logger = get_logger('Log');
		$logger->info($text);
	} 

	sub log_error
	{ 	
		my $self = shift if $_[0] eq __PACKAGE__ || ref($_[0]) eq __PACKAGE__;
		my $text = $_[0];
		my $data = $_[1];
		
		my $logger = get_logger('Log');
		$logger->error($text);
	} 

	sub not_error 
	{ 	
		my $self = shift if $_[0] eq __PACKAGE__ || ref($_[0]) eq __PACKAGE__;
		my $text = $_[0];
		my $data = $_[1];
		
		my $logger = get_logger('Not');
		$logger->error($text);
	}
	sub log_warn
	{
		my $self = shift if $_[0] eq __PACKAGE__ || ref($_[0]) eq __PACKAGE__;
		my $text = $_[0];
		my $data = $_[1];

		my $logger = get_logger('Log');
		$logger->warn($text);
	}
	sub not_warn
	{
		my $self = shift if $_[0] eq __PACKAGE__ || ref($_[0]) eq __PACKAGE__;
		my $text = $_[0];
		my $data = $_[1];

		my $logger = get_logger('Not');
		$logger->warn($text);
	}
	1;
