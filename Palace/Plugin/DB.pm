#!/usr/lib/perl
	
	package HPVF::Plugin::DB;
	use base 'HPVF::Plugin';
	use FindBin qw|$Bin|;
	use feature qw|state say switch|;

	use lib $Bin.'/HPVF/lib';
	
	use Log::Any::Adapter;
	Log::Any::Adapter->set('+Adapter');
	use Log::Any '$log';

	use Encode;
	use JSON;
	use DBI;

	$HPVF::Plugin::DB::EXPORT =
	{
		'db_connect' => 'subroutine',
	};


	sub export_name
	{
		my $pack = caller;
		map { $HPVF::Plugin::DB::EXPORT->{$_} and local *myglob = eval('$'.__PACKAGE__.'::'.'{'.$_.'}'); *{$pack.'::'.$_} = *myglob } @_;
	}

	sub import_name
	{
		my $pack = caller;
		map { local *myglob = ${$pack.'::'.'{'.$_.'}'}; *{__PACKAGE__.'::'.'{'.$_.'}'} = *myglob } @_;
	}

	sub db_connect
	{
		my ( $self, $db_name ) = @_;

		given( $db_name )
		{
			when('mysql')
			{
				$self->{'dbh'} ||= DBI->connect(
								$self->config()->{'db'}->{$db_name}->{'connect'}->{'dns'},
								$self->config()->{'db'}->{$db_name}->{'connect'}->{'user'}
				); 
			}
			when('sqlite')
			{
				$selt->{'dbh'} ||= DBI->connect(
								$self->config()->{'db'}->{$db_name}->{'connect'}->{'dns'},
								$self->config()->{'db'}->{$db_name}->{'connect'}->{'user'},
								$self->config()->{'db'}->{$db_name}->{'connect'}->{'pass'},
								$self->config()->{'db'}->{$db_name}->{'connect'}->{'error'}
				);
			}
		}
	}

	sub db_connect_2
	{
		my ( $self, $db_name, $reset ) = @_;

		state ( $mysql, $sqlite );

		given( $db_name )
		{
			when('mysql')
			{
				$reset ? $mysql = '' : '';
				$mysql ||= DBI->connect(
								$self->config()->{'db'}->{$db_name}->{'connect'}->{'dns'},
								$self->config()->{'db'}->{$db_name}->{'connect'}->{'user'}
				);
				$self->{'dbh'} = $mysql;
			}
			when('sqlite')
			{
				$reset ? $sqlite = '' : '';
				$sqlite ||= DBI->connect(
								$self->config()->{'db'}->{$db_name}->{'connect'}->{'dns'},
								$self->config()->{'db'}->{$db_name}->{'connect'}->{'user'},
								$self->config()->{'db'}->{$db_name}->{'connect'}->{'pass'},
								$self->config()->{'db'}->{$db_name}->{'connect'}->{'error'}
				);
				$self->{'dbh'} = $sqlite;
			}
		}
	}
	1;
