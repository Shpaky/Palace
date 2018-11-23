#!/usr/bin/perl

	package Palace;

	use 5.12.0;
	use lib qw|Palace Palace/lib|;

	state $s;

	sub new
	{
		my ( $class, $self ) = @_;

		return bless $self || {}, ref($class) ? ref($class) : $class;
	}

	sub env
	{
		state $env;
		$_[1] && ( $env ? $env = '' : '' or $env ||= $_[1] );
		$_[1] or return $env;
	}

	sub config
	{
		## for full hot configuration reload neccessary cleare %INC by keys of preloaded modules using logging
		state $conf;
		my $c;
		( lc ref($_[1]) eq 'hash' and ( $conf ? $conf = '' : '' or $conf ||= $_[1] ) ) ||
		( -f $_[1] and open RC, '<', $_[1] and map { $c .= $_ } <RC> and close RC and $conf = eval("$c;") );
		$_[1] or return $conf;
	}

	sub router
	{
		state $self = $_[0];								## think about sinse of use 'my'

		use Controller;
		$self->{'Controller'} ||= eval(__PACKAGE__.'::'.'Controller')->new();
	}

	sub go_to_route
	{
		my ( $self, $route, $method ) = @_;

		## existence check 'Controller' instance in the received object || access permissions ||
		if ( ref($self->{'Controller'}) ne __PACKAGE__.'::'.'Controller' )
		## if ( ! $self->isa(__PACKAGE__.'::'.'Controller') )				## think about since of use this method for all instances by inheritance tree
		{
			die 'Access to package from: ' . ref($self).' denied!';
		}
		state $router->{$route} ||= $self->{'Controller'}->new($route);

		## single tone
		## OOP-interface pass two object
		## $router->{$route}->$method($self);

		## procedure interface in method will available application instance
		## &{ref($router->{$route}).'::'.$method};

		## separate instance for either route
		$router->{$route}->$method();
	}

	sub plugin
	{
		use Plugin;
		$_[0]->{'Plugin'} ||= eval(__PACKAGE__.'::'.'Plugin')->new();
	}
	
	sub connect_plugin
	{
		my ( $self, $plugin ) = @_;

		$self->{'Plugin'}->{$plugin} ||= $self->{'Plugin'}->new($plugin);
	
		return $self->{'Plugin'}->{$plugin};
	}

	sub utils
	{
		use Utils;
		$_[0]->{'Utils'} ||= eval(__PACKAGE__.'::'.'Utils')->new();
	}

	sub call_utils
	{
		my ( $self, $utils ) = @_;

		$self->{'Utils'}->{$utils} ||= $self->{'Utils'}->new($utils);
	
		return $self->{'Utils'}->{$utils};
	}

	sub tools
	{
	#	use Tools;
		eval(__PACKAGE__.'::'.'Tools')->init_tools($_[0],$_[1]);
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
