#!/usr/bin/perl

	package Palace::Plugin::Model::DCBA::DataBase::MySQL;

	use 5.10.0;
	use base 'Palace::Plugin::Model::DCBA::DataBase';

	use DBI;


	##
	##	$self =
	##	{
	##		'table' => 'table_name',
	##		'field' => ['f1', 'f2,', 'f3],
	##		'limit' => 'numeric_value',
	##		'order' =>
	##		[
	##			'field',	|field by sorted|
	##			'inversion',	|flag of inversion|
	##		],
	##		'where' =>
	##		{
	##			|simple condition - field equal value|
	##			'field' => 'value',
	##			...............................................
	##			|inversion condition - field not equal value|
	##			'any keys' =>
	##			{
	##				'field_1' =>
	##				[
	##					'value_1', 'value_2', 'value_3'
	##				]
	##				'field_2' =>
	##				[
	##					'value_1', 'value_2', 'value_3'
	##				],
	##				'field_3' =>
	##			},
	##			...............................................
	##			|numeric condition - field more value|
	##			'>' =>
	##			{
	##				'field_1' =>
	##				[
	##					'value_1', 'value_2', 'value_3'
	##				]
	##				'field_2' =>
	##				[
	##					'value_1', 'value_2', 'value_3'
	##				],
	##				'field_3' =>
	##				[
	##					'value_1', 'value_2', 'value_3'
	##				],
	##			},
	##			................................................
	##			|numeric condition - field less value|
	##			'<' =>
	##			{
	##				'field_1' =>
	##				[
	##					'value_1', 'value_2', 'value_3'
	##				]
	##				'field_2' =>
	##				[
	##					'value_1', 'value_2', 'value_3'
	##				],
	##				'field_3' =>
	##				[
	##					'value_1', 'value_2', 'value_3'
	##				],
	##			},
	##			...............................................
	##			|numeric condition - field more or equal value|
	##			'>=' =>
	##			{
	##				'field_1' =>
	##				[
	##					'value_1', 'value_2', 'value_3'
	##				]
	##				'field_2' =>
	##				[
	##					'value_1', 'value_2', 'value_3'
	##				],
	##				'field_3' =>
	##				[
	##					'value_1', 'value_2', 'value_3'
	##				],
	##			},
	##			...............................................
	##			|numeric condition - field less or equal value|
	##			'<=' =>
	##			{
	##				'field_1' =>
	##				[
	##					'value_1', 'value_2', 'value_3'
	##				]
	##				'field_2' =>
	##				[
	##					'value_1', 'value_2', 'value_3'
	##				],
	##				'field_3' =>
	##				[
	##					'value_1', 'value_2', 'value_3'
	##				],
	##			},
	##		},
	##	};
	##

	our $detect_condition =
	{
		'>' => '>',
		'<' => '<',
		'>=' => '>=',
		'<=' => '<=',
		'!=' => '!='
	};

	sub select 
	{
		my ( $self ) = @_;
		
		$self->isa( __PACKAGE__ ) || return undef;

		my ( $c, $n, $nf, $cond, $update, $query );
		$self->{'where'} and map {
			my $f = $_;
			if ( lc(ref($self->{'where'}->{$f})) eq 'hash' )
			{
				map {
					my $nf = $_;
					map {
#						( $n || $c ) and $cond .= ' and '; $cond .= $nf .($detect_condition->{$f} or '!=').'"'. $_ .'"'; $n++
						scalar $cond and $cond .= ' and '; $cond .= $nf .($detect_condition->{$f} or '!=').'"'. $_ .'"';
					} @{$self->{'where'}->{$f}->{$nf}}
				} keys %{$self->{'where'}->{$f}}
			}
			else
			{
#				( $c || $n ) and $cond .= ' and '; $cond .= $_ .'='.'"'. $self->{'where'}->{$_} .'"'; $c++;
				scalar $cond and $cond .= ' and '; $cond .= $_ .'='.'"'. $self->{'where'}->{$_} .'"';
			}
		} keys %{$self->{'where'}};
		
		$query .= 'select ';
		$query .= scalar @{$self->{'field'}} ? join(',',@{$self->{'field'}}) : '*';
		$query .= ' from '. $self->{'table'};
		$query .= scalar keys %{$self->{'where'}} ? ' where '. $cond  : '';
		$query .= scalar @{$self->{'order'}} ? $self->{'order'}->[1] ? ' order by '. $self->{'order'}->[0] .' desc' : ' order by '. $self->{'order'}->[0] : '';
		$query .= $self->{'limit'} ? ' limit '.$self->{'limit'} : '';
		$query .= ';';


		my $sth = $self->{'dbh'}->prepare($query);
		eval{$sth->execute()};

		# 'NAME'
	       	my $hash_key_name = $sth->{FetchHashKeyName};
    		
		# 'hash relation field => index ' 
  		my $names_hash = $sth->FETCH("${hash_key_name}_hash");

		# 'fetching fields quantity'
        	my $num = $sth->FETCH('NUM_OF_FIELDS');
       
		# 'array fetching fields'	
		my $NAME = $sth->FETCH($hash_key_name);

		my ( $rows, $q, $array ) = ( {}, 0, [] );
		my @row = (undef) x $num;

        	eval
		{
			$sth->bind_columns(\(@row));							# 1904 /root/perl5/lib/perl5/x86_64-linux-thread-multi/DBI.pm 
	        	while ($sth->fetch) 
			{
#	      			my $ref = $rows;
#				@{$ref->{++$q}}{@$NAME} = @row;

				my $ref = {};
				@{$ref}{@$NAME} = @row;
				push @{$array}, $ref;
        		}
		};
##		my $hash = $sth->fetchall_hashref( 'email' );					# 2101 /root/perl5/lib/perl5/x86_64-linux-thread-multi/DBI.pm  
##		my $hash = $dbh->selectall_hashref($query, { 'Columns' => {} } );		# 1682 /root/perl5/lib/perl5/x86_64-linux-thread-multi/DBI.pm 
		$sth->finish;
		if ( $self->{'dbh'}->err )
		{
#			$log->warn(&COMMON::caller_info($CONFIG::level_nesting).DICTIONARY->new(\$CONFIG::system_language)->get_text_log('error_query').'|'.$self->{'dbh'}->err.'|');
			return 0;
		}
		else
		{
			if ( scalar @{$array} == 0 )
			{
#				$log->warn(&COMMON::caller_info($CONFIG::level_nesting).DICTIONARY->new(\$CONFIG::system_language)->get_text_log('empty_query').'|'.$query.'|');
				return 0;
			}
#			$log->info(DICTIONARY->new(\$CONFIG::system_language)->get_text_log('success_query').'|'.$query.'|');
			return $array;
		}
	}

	sub insert
	{
		my ( $self ) = @_;

		$self->isa( __PACKAGE__ ) || return undef;

		my $query = 'insert into '.$self->{'table'}.' ( '.join(', ', keys %{$self->{'data'}}).' ) '.'values ( '. join(',', map { "'".$_."'" } values %{$self->{'data'}}). ' );';


		my $res = $self->{'dbh'}->do($query);

		if ( $self->{'dbh'}->err )
		{
		#	$log->warn(&COMMON::caller_info($CONFIG::level_nesting).DICTIONARY->new(\$CONFIG::system_language)->get_text_log('error_query').'|'.$self->{'dbh'}->err.'|');
			return 0;
		}
		else
		{	if ( $res eq '0E0' )
			{
		#		$log->warn(&COMMON::caller_info($CONFIG::level_nesting).DICTIONARY->new(\$CONFIG::system_language)->get_text_log('empty_query').'|'.$query.'|');
				return 0;
			}
		#	$log->info(DICTIONARY->new(\$CONFIG::system_language)->get_text_log('success_query').'|'.$query.'|');
			return $self->{'data'};
		}
	}
	
	sub update
	{ 
		my ( $self ) = @_;

		$self->isa( __PACKAGE__ ) || return undef;
		
		my ( $c, $u, $n, $nf, $cond, $update, $query );

		$self->{'where'} and map {
			my $f = $_;
			if ( lc(ref($self->{'where'}->{$f})) eq 'hash' )
			{
				map {
					my $nf = $_;
					map {
						( $n || $c ) and $cond .= ' and '; $cond .= $nf .($detect_condition->{$f} or '!=').'"'. $_ .'"'; $n++
					} @{$self->{'where'}->{$f}->{$nf}}
				} keys %{$self->{'where'}->{$f}}
			}
			else
			{
				( $c || $n ) and $cond .= ' and '; $cond .= $_ .'='.'"'. $self->{'where'}->{$_} .'"'; $c++;
			}
		} keys %{$self->{'where'}};
		$self->{'data'}  && map { $u and $update .= ', '; $update .= $_ .'='.'"'. $self->{'data'}->{$_} .'"'; $u++; } keys(%{$self->{'data'}});

		$query .= 'update ';
		$query .= $self->{'table'}.' set ';
		$query .= $update ? $update : '';
		$query .= $cond ? ' where '.$cond : '';
		$query .= ';';


		my $res = $self->{'dbh'}->do($query);

		if ( $self->{'dbh'}->err )
		{
#			$log->warn(&COMMON::caller_info($CONFIG::level_nesting).DICTIONARY->new(\$CONFIG::system_language)->get_text_log('error_query').'|'.$self->{'dbh'}->err.'|');
			return 0;
		}
		else
		{	if ( $res eq '0E0' )
			{
#				$log->warn(&COMMON::caller_info($CONFIG::level_nesting).DICTIONARY->new(\$CONFIG::system_language)->get_text_log('empty_query').'|'.$query.'|');
				return 0;
			}
#			$log->info(DICTIONARY->new(\$CONFIG::system_language)->get_text_log('success_query').'|'.$query.'|');
			return $res;
		}
	}

	sub delete
	{
		my ( $self ) = @_;

		$self->isa( __PACKAGE__ ) || return undef;

		my ( $c, $n, $nf, $cond, $update, $query );
		$self->{'where'} and map {
			my $f = $_;
			if ( lc(ref($self->{'where'}->{$f})) eq 'hash' )
			{
				map {
					my $nf = $_;
					map{
						( $n || $c ) and $cond .= ' and '; $cond .= $nf .($detect_condition->{$f} or '!=').'"'. $_ .'"'; $n++
					} @{$self->{'where'}->{$f}->{$nf}}
				} keys %{$self->{'where'}->{$f}}
			}
			else
			{
				( $c || $n ) and $cond .= ' and '; $cond .= $_ .'='.'"'. $self->{'where'}->{$_} .'"'; $c++;
			}
		} keys %{$self->{'where'}};

		$query .= 'delete ';
		$query .= 'from '.$self->{'table'};
		$query .= $cond ? ' where '.$cond : '';
		$query .= ';';

		my $res = $self->{'dbh'}->do($query);

		if ( $self->{'dbh'}->err )
		{
	#		$log->warn(&COMMON::caller_info($CONFIG::level_nesting).DICTIONARY->new(\$CONFIG::system_language)->get_text_log('error_query').'|'.$self->{'dbh'}->err.'|');
			return 0;
		}
		else
		{	if ( $res eq '0E0' )
			{
	#			$log->warn(&COMMON::caller_info($CONFIG::level_nesting).DICTIONARY->new(\$CONFIG::system_language)->get_text_log('empty_query').'|'.$query.'|');
				return 0;
			}
	#		$log->info(DICTIONARY->new(\$CONFIG::system_language)->get_text_log('success_query').'|'.$query.'|');
			return $res;
		}
	}
	1;
