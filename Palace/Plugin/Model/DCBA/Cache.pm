#!/usr/bin/perl

	package Palace::Plugin::Model::DCBA::Cache;
	use base 'Palace::Plugin::Model::DCBA';
	use 5.10.0;

	
	sub get
	{ 
		my ( $self ) = @_;

		my $data = eval('&'.eval{ref($self).'::'.$self->{'cache'}}.'::'.'get('.$self->{'id'}.')');

		return [ $data ] unless scalar @{$self->{'field'}};

		map { delete($data->{$_}) } grep { not $_ ~~ $self->{'field'} } keys %$data;
	
		return scalar keys(%{$data}) == scalar @{$self->{'field'}} ? [ $data ] : undef;
	}

	sub set
	{
		my ( $self ) = @_; 

		my $data = eval('&'.eval{ref($self).'::'.$self->{'cache'}}.'::'.'get('.$self->{'id'}.')');

		map { $data->{$_} = $self->{'data'}->{$_} } keys %{$self->{'data'}};
		
		eval('&'.ref($self).'::'.$self->{'cache'}.'::'.'set('.$self->{'id'}.','.'{ '.'map { $_ => $data->{$_} } keys %{$data}'.' }'.')');
	}

	sub remove
	{
		my ( $self ) = @_;

		if ( $self->{'field'} )
		{
			my $data = eval('&'.eval{ref($self).'::'.$self->{'cache'}}.'::'.'get('.$self->{'id'}.')');
			map { delete($data->{$_}) } @{$self->{'field'}};
		
			eval('&'.ref($self).'::'.$self->{'cache'}.'::'.'set('.$self->{'id'}.','.'{ '.'map { $_ => $data->{$_} } keys %{$data}'.' }'.')');
		}
		else
		{
			eval('&'.eval{ref($self).'::'.$self->{'cache'}}.'::'.'delete('.$self->{'id'}.')');
		}
	} 
	1;


	package Palace::Plugin::Model::DCBA::Cache::Memcached;

	sub get
	{ 
		0;
	} 
		
	sub set
	{ 
		1;
	} 

	sub delete
	{ 
		1;
	} 

	package Palace::Plugin::Model::DCBA::Cache::Redis;

	sub get
	{
		my ( $id ) = @_;
		my ( $s,$data );

		open  RD, '<', '/tmp/CACHE_STORE'; $s .= $_ for <RD>; close RD;
		eval("$s;");

		return $data->{'id'}->{$id};
	} 
		
	sub set
	{
		my ( $id, $ndata ) = @_;

		open  RD, '<', '/tmp/CACHE_STORE'; $s .= $_ for <RD>; close RD;
		eval("$s;");

		$data->{'id'}->{$id} = $ndata;

		open  WD, '>', '/tmp/CACHE_STORE';
		say   WD Data::Dumper->Dump([$data],['data']);
		close WD;

		return $data->{'id'}->{$id};
	} 

	sub delete 
	{ 
		my ( $id ) = @_;

		open  RD, '<', '/tmp/CACHE_STORE'; $s .= $_ for <RD>; close RD;
		eval("$s;");

		delete($data->{'id'}->{$id});

		open  WD, '>', '/tmp/CACHE_STORE';
		say   WD Data::Dumper->Dump([$data],['data']);
		close WD;

		return $data->{'id'}->{$id};
	} 

	1;
