#!/usr/bin/perl

	package Palace::Plugin::Model::DCBA::DataBase;

	use 5.10.0;
	use base 'Palace::Plugin::Model::DCBA';


	sub new
	{
		my ( $self, $class ) = @_;

		$self->SUPER::new('DataBase'.'::'.$class);
	}

	sub get
	{
		my ( $self ) = @_;

		state $db ||= $self->new($self->{'db'});

		my ( $data )  = $db->set_data({map { $_ => $self->{$_} } grep {/field|table|where|order|limit/} keys %{$self} })->select();

		return $data;
	}

	sub set
	{
		my ( $self ) = @_;
		
		state $db ||= $self->new($self->{'db'});
		
		my ( $data )  = $db->set_data({map { $_ => $self->{$_} } grep {/table|data/} keys %{$self} })->insert();
		
		return $data;
	}

	sub delete
	{
		my ( $self ) = @_;

		state $db ||= $self->new($self->{'db'});

		if ( scalar @{$self->{'field'}} )
		{
			map { $self->{'data'}->{$_} = undef } @{$self->{'field'}};
			my $resp = $db->set_data({map { $_ => $self->{$_} } grep {/table|data|where/} keys %{$self} })->update();
	
			return $resp;
		}
		else
		{
			my $resp = $db->set_data({map { $_ => $self->{$_} } grep {/table|where/} keys %{$self} })->delete();
			
			return $resp;
		}
	}

	sub update
	{
		my ( $self ) = @_;

		state $db ||= $self->new($self->{'db'});

		my $resp = $db->set_data({map { $_ => $self->{$_} } grep {/table|data|where/} keys %{$self} })->update();

		return $resp;
	}
	1;
