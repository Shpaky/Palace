#!/usr/bin/perl

	package Palace::Plugin;
	use base 'Palace';
	use lib './Plugin';
	use 5.12.0;

	state $s;

	sub new
	{
		my ( $self, $class ) = @_;

		if ( ref($self) )
		{
			$self->{$class} ||= $self->runtime_require(__PACKAGE__.'::'.$class)->new();

			given ($class)
			{
				when('MP4SPLIT') { 1; }
				when('FFMPEG')
				{
					$self->{$class}->utils(
					[
						'check_root_project',
						'check_uuid_project',
						'fetch_russian_name',
						'eqq', 'create_pipe',
						'get_lang','get_line',
						'sig_user1', 'kill_pid',
						'write_pipe','sig_pipe',
						'read_value',
					])
				}
				when('RSYNC') { $self->{$class}->utils(['get_line']) }
				when('DB::MYSQL') { $self->{$class}->db_connect('mysql') }
			}

			return $self->{$class};
		}
		
		return bless {}, $self;
	}

	sub runtime_require
	{
		my ( $self, $pckgnm ) = @_;
		
		$pckgnm !~ /^[a-z0-9:_\-]+$/i and die 'Invalid package name', $pckgnm;

		my $source_pckgnm = $pckgnm;
		while ( $pckgnm =~ /(.*)(::[a-z0-9_\-]+)$/i )
		{
			$pckgnm eq __PACKAGE__ and last;

			my $up_pack = $1;

			my $filename = $pckgnm;
			$filename =~ s|::+|/|g;
			$filename =~ /\.pm$/ or $filename .= '.pm';

			exists($INC{$filename}) or ( -f $filename && eval('require '.$pckgnm.';') ) or ( delete($INC{$filename}), die($@,$!) );
			$pckgnm = $up_pack;
		}
		return $source_pckgnm;
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
