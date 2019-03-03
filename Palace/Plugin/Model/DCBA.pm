#!/usr/bin/perl

	package Palace::Plugin::Model::DCBA;

	use 5.10.0;
	use base qw|Palace::Plugin::Model DataMatching|;
	use lib './DCBA';


	state $s = {};

	state $fields =
	[
		'table', 'field', 'where', 'data', 'order', 'limit', 'id', 'cache', 'db'
	];

	state $payload =
	[
		'table', 'field', 'where', 'data', 'order', 'limit', 'id'
	];


	sub new
	{
		my ( $self, $class ) = @_;

		$self->SUPER::new('DCBA'.'::'.$class);
	}

	sub get
	{
		my ( $self ) = @_;
		my ( $data );

		$self->isa( __PACKAGE__ ) || return undef;
		
		state $cache ||= $self->new('Cache');
		state $db ||= $self->new('DataBase');

#		$self->check_reference_object();
	
		if ( $self->{'id'} and $data = $cache->set_data({ map { $_ => $self->{$_} } grep {/field|id|cache/} keys %{$self} })->get() ) { return $data }
		else 
		{ 	
#			my $cdb = &ACCORDANCE::check_reference_obj($self->{'dbh'}, 'DBI::db');			## replace to lower level
#			my $ctb = &ACCORDANCE::check_table_exist($self->{'table'});				## may replace to lower level
#			
			if ( $self->{'where'} )
			{ 
#				my $ctw = &ACCORDANCE::check_type_instance($self->{'where'}, 'HASH');		## may replace to lower level
#
#				if ( $ctw )									## may replace to lower level
#				{
#					map { &ACCORDANCE::check_field_value_valid($self->{'table'},$_,$self->{'where'}->{$_}) || return undef } grep { $self->{'where'}->{$_} } keys%{$self->{'where'}};
#				}
#				else 
#				{
#					return undef;
#				}
			}
#
#			( $cdb and $ctb ) || return undef;
#						
			if ( $data = $db->set_data({map { $_ => $self->{$_} } grep {/field|table|where|order|limit|db/} keys %{$self} })->get() )
			{
				if ( $self->{'id'} and scalar @$data == 1 )
				{
					$cache->set_data({'data' => $data->[0], 'id' => $self->{'id'}, 'cache' => $self->{'cache'} })->set();
				}
				else
				{
					## unities two action in single condition, this scheme allow use 'id' without relation with table of database
					if ( my $fid = $self->fetch_id_by_table() and $self->check_auto_obtain_data_by_id_to_cache() )
					{
						my $id;
						map {
							( $data->[$_]->{$fid} or $id ||= $db->set_data({'where' => $self->{'where'}, 'field' => [ $fid ], 'db' => $self->{'db'}, 'table' => $self->{'table'}})->get() )
							&& $cache->set_data({'data' => $data->[$_], 'id' => $data->[$_]->{$fid} || $id->[$_]->{$fid}, 'cache' => $self->{'cache'}})->set();
						} 0..@{$data}-1;
					}
				}
				return $data;
			}
			else
			{
				return undef;
			}
		}
	}
	sub set
	{
		my ( $self ) = @_;

		$self->isa( __PACKAGE__ ) || return undef;

		state $cache ||= $self->new('Cache');
		state $db ||= $self->new('DataBase');
		
#		my $cdb = &ACCORDANCE::check_reference_obj($self->{'dbh'}, 'DBI::db');
#		my $ctb = &ACCORDANCE::check_table_exist($self->{'table'});
#
#		( $cdb and $ctb ) || return undef;
#
#		if ( &ACCORDANCE::check_exists_necessary_data($self->{'data'},0) )
#		{
#			my ( $ctd ) = &ACCORDANCE::check_type_instance($self->{'data'}, 'HASH');
#
#			if ( $ctd )
#			{
#				my ( $cqf ) = &ACCORDANCE::check_quantity_matching_fields($self->{'table'}, $self->{'data'});
#
#				if ( $cqf )
#				{
#					map { &ACCORDANCE::check_field_table_exist($self->{'table'}, $_) || return undef } keys %{$self->{'data'}};
#					map { &ACCORDANCE::check_field_value_valid($self->{'table'},$_,$self->{'data'}->{$_}) || return undef } grep { $self->{'data'}->{$_} } keys %{$self->{'data'}};  ## in case empty value or 0 will to skipped
#				}
#				else
#				{
#					return undef;
#				}
#			}
#			else
#			{
#				return undef;
#			}
#		}
#		else
#		{
#			return undef;
#		}

		if ( $data = $db->set_data({map { $_ => $self->{$_} } grep {/table|data|db/} keys %{$self} })->set() )
		{
			if ( $self->{'id'} )
			{
				$cache->set_data({ map { $_ => $self->{$_} } grep {/data|id|cache/} keys %{$self} })->set();
			}
			else
			{
				if ( my $fid = $self->fetch_id_by_table() and $self->check_auto_insert_data_by_id_to_cache() )
				{
					my $id = $db->set_data({'where' => $self->{'data'}, 'field' => [ $fid ], 'db' => $self->{'db'}, 'table' => $self->{'table'}})->get();
					map {
						$cache->set_data({'data' => $self->{'data'}, 'id' => $_->{$fid}, 'cache' => $self->{'cache'}})->set()
					} @{$id};
				}
			}
			return $data;
		}
		else
		{
			return undef;
		}
	}

	sub remove
	{
		my ( $self ) = @_;

		$self->isa( __PACKAGE__ ) || return undef;

		state $cache ||= $self->new('Cache');
		state $db ||= $self->new('DataBase');


#		my $cdb = &ACCORDANCE::check_reference_obj($self->{'dbh'}, 'DBI::db');
#		my $ctb = &ACCORDANCE::check_table_exist($self->{'table'});

#		( $cdb and $ctb ) || return undef;

		if ( $self->{'where'} )
		{
#			my $ctw = &ACCORDANCE::check_type_instance($self->{'where'}, 'HASH');
#
#			if ( $ctw )
#			{
#				map { &ACCORDANCE::check_field_value_valid($self->{'table'},$_,$self->{'where'}->{$_}) || return undef } keys %{$self->{'where'}};
#			}
#			else
#			{
#				return undef;
#			}
		}

		if ( $self->{'id'} )
		{
			$cache->set_data({ map { $_ => $self->{$_} } grep {/field|id|cache/} keys %{$self} })->remove() ;
		}
		else
		{
			if ( my $fid = $self->fetch_id_by_table() and $self->check_auto_delete_data_by_id_in_cache() )
			{
				my $id = $db->set_data({'where' => $self->{'where'}, 'field' => [ $fid ], 'db' => $self->{'db'}, 'table' => $self->{'table'}})->get();
				map {
					$cache->set_data({'field' => $self->{'field'}, 'id' => $_->{$fid}, 'cache' => $self->{'cache'}})->remove()
				} @{$id};
			}
		}
		if ( my $resp = $db->set_data({map { $_ => $self->{$_} } grep {/table|field|where|db/} keys %{$self} })->delete() )
		{
			return $resp;
		}
		else
		{
			return undef;
		}
	}

	sub update
	{
		my ( $self ) = @_;

		$self->isa( __PACKAGE__ ) || return undef;

		state $cache ||= $self->new('Cache');
		state $db ||= $self->new('DataBase');

#		my $cdb = &ACCORDANCE::check_reference_obj($self->{'dbh'}, 'DBI::db');
#		my $ctb = &ACCORDANCE::check_table_exist($self->{'table'});

#		( $cdb and $ctb ) || return undef;

		if ( $self->{'where'} )
		{
#			my $ctw = &ACCORDANCE::check_type_instance($self->{'where'}, 'HASH');

#			if ( $ctw )
#			{
#				map { &ACCORDANCE::check_field_value_valid($self->{'table'},$_,$self->{'where'}->{$_}) || return undef } grep { $self->{'where'}->{$_} } keys %{$self->{'where'}};
#			}
#			else
#			{
#				return undef;
#			}
		}

#		if ( &ACCORDANCE::check_exists_necessary_data($self->{'data'},0) )
#		{
#			my $ctd = &ACCORDANCE::check_type_instance($self->{'data'}, 'HASH');

#			if ( $ctd )
#			{
#				map { &ACCORDANCE::check_field_table_exist($self->{'table'},$_) || return undef } keys %{$self->{'data'}};
#				map { &ACCORDANCE::check_field_value_valid($self->{'table'},$_,$self->{'data'}->{$_}) || return undef } grep { $self->{'data'}->{$_} } keys %{$self->{'data'}};  ## in case empty value or 0 will to skipped
#			}
#			else
#			{
#				return undef;
#			}
#		}
#		else
#		{
#			return undef;
#		}

		if ( $self->{'id'} )
		{
			$cache->set_data({map { $_ => $self->{$_} } grep {/data|id|cache/} keys %{$self}})->set();
		}
		else
		{
			if ( my $fid = $self->fetch_id_by_table() and $self->check_auto_update_data_by_id_to_cache() )
			{
				my $id = $db->set_data({'where' => $self->{where}, 'field' => [ $fid ], 'db' => $self->{'db'}, 'table' => $self->{'table'}})->get();
				map {
					$cache->set_data({'data' => $self->{'data'}, 'id' => $_->{$fid}, 'cache' => $self->{'cache'}})->set()
				} @{$id};
			}
		}
		if ( my $resp = $db->set_data({map { $_ => $self->{$_} } grep {/table|where|data|db/} keys %{$self}})->update() ) { return $resp } else { return undef }
	}

	sub fetch_id_by_table
	{
		$_[0]->config()->{'db'}->{lc($_[0]->{'db'})}->{'tables'}->{$_[0]->{'table'}}->{'id'};
	}

	sub check_auto_update_data_by_id_to_cache
	{
		$_[0]->config()->{'db'}->{lc($_[0]->{'db'})}->{'tables'}->{$_[0]->{'table'}}->{'auto_update_data_by_id_to_cache'};
	}
	
	sub check_auto_obtain_data_by_id_to_cache
	{
		$_[0]->config()->{'db'}->{lc($_[0]->{'db'})}->{'tables'}->{$_[0]->{'table'}}->{'auto_obtain_data_by_id_to_cache'};
	}

	sub check_auto_delete_data_by_id_in_cache
	{
		$_[0]->config()->{'db'}->{lc($_[0]->{'db'})}->{'tables'}->{$_[0]->{'table'}}->{'auto_delete_data_by_id_to_cache'};
	}
	
	sub check_auto_insert_data_by_id_to_cache
	{
		$_[0]->config()->{'db'}->{lc($_[0]->{'db'})}->{'tables'}->{$_[0]->{'table'}}->{'auto_insert_data_by_id_to_cache'};
	}

	sub check_reference_object
	{
		$_[0]->SUPER::check_reference_object();
	}

	sub set_data
	{
		lc ref($_[1]) eq 'hash'
		? map { defined($_[1]->{$_}) ? $_[0]->{$_} = $_[1]->{$_} : ( $_ ~~ $payload and delete $_[0]->{$_} ) } @{$fields}	## better suited for big instances and small lists
		: die 'Second parameter necessary was be link to hash!';

		return $_[0]
	}
	1;
