#!/usr/bin/perl

	package Palace::Plugin::Model::DCBA;
	use base 'Palace::Plugin::Model';
	use 5.10.0;

	use lib './DCBA';
#	use Cache;
#	use DB;
#	use ACCORDANCE;
	

	state $s;

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

	
		if ( $self->{'id'} and $data = $cache->set_data({ map { $_ => $self->{$_} } grep {/field|id|cache/} keys %{$self} })->get() ) { return $data }
		else 
		{ 	
#			my $cdb = &ACCORDANCE::check_reference_obj($self->{'dbh'}, 'DBI::db');
#			my $ctb = &ACCORDANCE::check_table_exist($self->{'table'});
#			
			if ( $self->{'where'} )
			{ 
#				my $ctw = &ACCORDANCE::check_type_instance($self->{'where'}, 'HASH');
#
#				if ( $ctw )
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
					if ( my $fid = $self->fetch_id_by_table() and $self->check_auto_set_data_by_id_to_cache() )
					{
						map {
							$_->{$fid} and $cache->set_data({'data' => $_, 'id' => $_->{$self->fetch_id_by_table()}, 'cache' => $self->{'cache'}})->set()
						} @{$data};
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
				$cache->set_data({ map { $_ => $self->{$_} } grep {/data|id|cache/} keys %{$self} })->set() ;
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
				my $id = $db->set_data({'where' => $self->{where}, 'field' => [ $fid ], 'db' => $self->{'db'}, 'table' => $self->{'table'}})->get();
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
		return 'id';
	}

	sub check_auto_set_data_by_id_to_cache
	{
		0;
	}

	sub check_auto_update_data_by_id_to_cache
	{
		1;
	}
	
	sub check_auto_obtain_data_by_id_to_cache
	{
		1;
	}

	sub check_auto_delete_data_by_id_in_cache
	{
		0;
	}
	
	sub check_auto_insert_data_by_id_to_cache
	{
		0;
	}

	sub set_data
	{
		lc ref($_[1]) eq 'hash'
		? map { $_[0]->{$_} = $_[1]->{$_} or delete $_[0]->{$_} } ( 'table', 'field', 'where', 'data', 'order', 'limit', 'id', 'cache', 'db' )  ## better suited for big instances and small lists
	##	? map { $_[0]->{$_} = $_[1]->{$_} or delete $_[0]->{$_} } grep { /(table|field|where|data|order|limit|id|cache|db)/ } keys %{$_[0]}	## better suited for small instances and big lists
		: die 'Second parameter necessary was be link to hash!';

		return $_[0]
	}
	1;
