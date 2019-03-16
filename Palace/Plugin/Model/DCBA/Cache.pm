#!/usr/bin/perl

	package Palace::Plugin::Model::DCBA::Cache;
	use base 'Palace::Plugin::Model::DCBA';
	use 5.10.0;

	
	sub select
	{ 
		my ( $self ) = @_;

		my $data = eval('&'.eval{ref($self).'::'.$self->{'cache'}}.'::'.'select('.$self->{'id'}.')');

		return [ $data ] unless scalar @{$self->{'field'}};

		map { delete($data->{$_}) } grep { not $_ ~~ $self->{'field'} } keys %$data;
	
		return scalar keys(%{$data}) == scalar @{$self->{'field'}} ? [ $data ] : undef;
	}

	sub insert
	{
		my ( $self ) = @_; 

		my $data = eval('&'.eval{ref($self).'::'.$self->{'cache'}}.'::'.'select('.$self->{'id'}.')');

		map { $data->{$_} = $self->{'data'}->{$_} } keys %{$self->{'data'}};
		
		eval('&'.ref($self).'::'.$self->{'cache'}.'::'.'insert('.$self->{'id'}.','.'{ '.'map { $_ => $data->{$_} } keys %{$data}'.' }'.')');
	}

	sub delete
	{
		my ( $self ) = @_;

#		if ( scalar @{$self->{'field'}} )	## in case if transmitted field not matching to array reference or array will be empty then will remove full record by retrieved 'id'
		if ( $self->{'field'} )
		{
			my $data = eval('&'.eval{ref($self).'::'.$self->{'cache'}}.'::'.'select('.$self->{'id'}.')');
			map { delete($data->{$_}) } @{$self->{'field'}};
		
			eval('&'.ref($self).'::'.$self->{'cache'}.'::'.'insert('.$self->{'id'}.','.'{ '.'map { $_ => $data->{$_} } keys %{$data}'.' }'.')');
		}
		else
		{
			eval('&'.eval{ref($self).'::'.$self->{'cache'}}.'::'.'delete('.$self->{'id'}.')');
		}
	} 
	1;


	package Palace::Plugin::Model::DCBA::Cache::Memcached;

	sub select
	{ 
		0;
	} 
		
	sub insert
	{ 
		1;
	} 

	sub delete
	{ 
		1;
	} 

	package Palace::Plugin::Model::DCBA::Cache::Redis;

	sub select
	{
		my ( $id ) = @_;
		my ( $s,$data );

		open  RD, '<', '/tmp/CACHE_STORE'; $s .= $_ for <RD>; close RD;
		eval("$s;");

		return $data->{'id'}->{$id};
	} 
		
	sub insert
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
