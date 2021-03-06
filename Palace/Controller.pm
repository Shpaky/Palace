#!/usr/bin/perl

	package Palace::Controller;
	use base 'Palace';
	use lib './Controller';
	use 5.12.0;

	state $s;

	sub new
	{
		my ( $self, $class ) = @_;

		if ( ref($self) )
		{
			$self->{$class} ||= $self->runtime_require(__PACKAGE__.'::'.$class)->new();

			return $self->{$class};
		}
		
		return bless {}, $self;
	}

	sub runtime_require
	{
		my ( $self, $pckgnm ) = @_;
		
		$pckgnm !~ /^[a-z0-9:_\-]+$/i and die 'Invalid package name', $pckgnm;
		
		my $filename = $pckgnm;
		$filename =~ s|::+|/|g;
		$filename =~ /\.pm$/ or $filename .= '.pm';

		exists($INC{$filename}) or ( -f $filename && eval('require '.$pckgnm.';') ) or ( delete($INC{$filename}), die($@) );
		
		return $pckgnm;
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
