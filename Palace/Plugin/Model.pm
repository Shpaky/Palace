#!/usr/bin/perl

	package Palace::Plugin::Model;
	use base 'Palace::Plugin';
	use 5.10.0;


	state $s;

	sub new
	{
		my ( $self, $class ) = @_;

		my $self = $self->SUPER::new('Model'.'::'.$class);

		given ( (split(/[:]+/,$class))[-1] )
		{
			when($self->SUPER::config->{'model'}->{'db'}) { $self->connect_db() }
		}
		$self;
	}

	sub config
	{
		state $conf;
		$conf || ( open RC, '<', $_[0]->SUPER::config()->{'model'}->{'conf_path'} and map { $c .= $_ } <RC> and close RC and $conf = eval("$c;") );
		return $conf;
	}

	sub detect_plugin
	{
		my ( $self ) = @_;

		return __PACKAGE__.'::'.$self->SUPER::config()->{'model'}->{'plugin'};
	}

	sub detect_cache
	{
		my ( $self ) = @_;

		return $self->SUPER::config()->{'model'}->{'cache'};
	}

	sub detect_db
	{
		my ( $self ) = @_;

		return $self->SUPER::config()->{'model'}->{'db'};
	}

	sub connect_db
	{
		my ( $self ) = @_;

		state ( $mysql, $postgresql, $sqlite );

		given(lc($self->SUPER::config()->{'model'}->{'db'}))
		{
			when('mysql')
			{
				$self->{'reset'} and $mysql = '';
				$mysql ||= DBI->connect(
								$self->SUPER::config()->{'db'}->{lc($self->SUPER::config()->{'model'}->{'db'})}->{'connect'}->{'dns'},
								$self->SUPER::config()->{'db'}->{lc($self->SUPER::config()->{'model'}->{'db'})}->{'connect'}->{'user'},
								$self->SUPER::config()->{'db'}->{lc($self->SUPER::config()->{'model'}->{'db'})}->{'connect'}->{'pass'}
				);
				$self->{'dbh'} = $mysql;
			}
		}
	}

	sub get_value
        {
                $s->{$_[1]} ||= $_[0]->{$_[1]};
                return $s->{$_[1]};
        }

        sub set_value
        {
                $_[0]->{$_[1]} = $_[2];
                delete $s->{$_[1]};
		return $_[0];
        }

	sub set_data
	{
		lc ref($_[1]) eq 'hash'
		? map { $_[0]->{$_} = $_[1]->{$_} and delete $s->{$_} } keys %{$_[1]}
		: die 'Second parameter necessary was be link to hash!';

		return $_[0]
	}
	1;
