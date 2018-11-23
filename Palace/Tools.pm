#!/usr/bin/perl

	package Palace::Tools;
	use base 'Palace';
	use feature qw|state say|;
	use FindBin qw|$Bin|;

	use lib $Bin.'/HPVF/lib';

	use Log::Any::Adapter;
	Log::Any::Adapter->set('+Adapter');
	use Log::Any '$log';

	use Encode;
	use Locale::Country;
	use Locale::Language;
	use JSON;
	use Fcntl qw|:DEFAULT :flock|;
	use POSIX;
	use File::Copy;
	use File::Path qw|make_path|;
	use File::Glob qw(bsd_glob);
	
	$HPVF::Utils::EXPORT =
	{
		'check_root_project' => 'subroutine',
		'fetch_russian_name' => 'subroutine',
		'change_substr_file' => 'subroutine',
		'change_permissions' => 'subroutine',
		'get_lang' => 'subroutine',
		'get_line' => 'subroutine',
		'sig_pipe' => 'subroutine',
		'init_log' => 'subroutine',
		'read_dir' => 'subroutine',
		'kill_pid' => 'subroutine',
		'uuid_generation' => 'subroutine',
		'encode_utf8_off' => 'subroutine',
		'locked_open' => 'subroutine',
		'create_pipe' => 'subroutine',
		'create_path' => 'subroutine',
		'encode_to_json' => 'subroutine',
		'make_directory' => 'subroutine',
		'eqq' => 'subroutine',
		'check_exist_file' => 'subroutine',
		'write_pipe' => 'subroutine',
		'read_value' => 'subroutine',
		'change_uid' => 'subroutine',
		'sig_child' => 'subroutine',
		'sig_user1' => 'subroutine',
		'get_dates' => 'subroutine',
		'move_file' => 'subroutine',
	};


	sub init_tools
	{
		my ( $class, $self, $tools ) = @_;
		
		&export_name($self,$tools);
	}

	sub export_name
	{
#		begin debug
#		say '-' x 9;
#		say caller(1);
#		say '-' x 9;
#		say '+' x 9;
#		say caller(2);
#		say '+' x 9;
#		say '=' x 9;
#		say caller(3);
#		say '=' x 9;
#		say '~' x 9;
#		say caller(4);
#		say '~' x 9;
#		say '!' x 9;
#		say caller(5);
#		say '!' x 9;
#		say '*' x 9;
#		say caller(6);
#		say '*' x 9;
#		say '&' x 9;
#		say caller(7);
#		say '&' x 9;
#		say '#' x 9;
#		say caller(8);
#		say '#' x 9;
#		end debug
#		my $pack = caller(2);
		my $pack = ref($_[0]);
		map { $HPVF::Tools::EXPORT->{$_} and local *myglob = eval('$'.__PACKAGE__.'::'.'{'.$_.'}'); *{$pack.'::'.$_} = *myglob } @{$_[1]};
	}


	sub create_path
	{
		my ( $path, $at ) = @_;

		lc(ref($at)) eq 'hash' ? make_path($path,$at) : make_path($path);
	}

	sub move_file
	{
		my ( $cur_name, $tar_name ) = @_;

		move $cur_name, $tar_name;
	}

	sub read_dir
	{
		my $files;

		sub rd
		{
			$_[0] || return $files;

			my ( $path ) = @_;

			opendir RD, $path;
			for ( readdir RD )
			{
				/^[.]+$/ and next;

				push @$files, $path.'/'.$_;

				-d $path.'/'.$_ and &rd($path.'/'.$_);
			}
			closedir RD;
		}

		return \&rd;
	}

	sub change_uid
	{
		my ( $uid, $gid, $file ) = @_;

		chown $uid, $gid, $file;
	}

	sub change_permissions
	{
		my ( $mask, $file ) = @_;

		chmod $mask, $file;
	}
	sub change_group
	{
		my ( $file, $gid ) = @_;

		chown $file, $gid;
	}

	sub change_substr_file
	{
		my ( $file, $substr1, $substr2, $copy ) = @_;

		copy($file,$file.'_temp') or return undef;

		open RF, '<', $file.'_temp' or return undef;
		open WF, '>', $file or return undef;
		for (<RF>)
		{
			s/$substr1/$substr2/g;
			print WF or return undef;
		}
		close WF;
		close RF;

		$copy || unlink $file.'_temp' || undef;
	}

	sub sig_user1
	{
		my ( $sig ) = @_;

		my $sigset = POSIX::SigSet->new($sig) and sigprocmask(SIG_BLOCK, $sigset) or
		$log->error('|'.$$.'|'.'Can`t block: \''.$sig.'\'.') and die;

		sleep 1;
		if ( -p $HPVF::pipe )
		{
			if ( my $child = open STDIN, '-|' )
			{
				local $SIG{CHLD} = 'IGNORE';
				sleep 1;
				&kill_pid('TERM',$child);
				my $v = <STDIN>;
				int($v) and
				(
					$log->error('|'.$$.'|'.'Process child |'.$v.'| of convert video, execute failed.') and
					map { &kill_pid('TERM',$_) } values %{$HPVF::pid} and
					exit
				)
			}
			else
			{
				my $v = &read_value($HPVF::pipe);
				print $v;
				exit;
			}
		}
		else
		{
			$log->warn('|'.$$.'|'.'Received signal, but pipe not exist.');
			&create_pipe($HPVF::pipe,'0700');
			&sig_user1();
		}

		sigprocmask(SIG_UNBLOCK, $sigset) or
		$log->error('|'.$$.'|'.'Can`t unblock: \''.$sig.'\'.') and die;
	}

	sub sig_pipe
	{
		local $SIG{PIPE} = 'IGNORE';
		local $SIG{PIPE} = 'DEFAULT';
	}

	sub create_pipe
	{
		my ( $path, $mode ) = @_;

		POSIX::mkfifo($path, $mode);
	}

	sub write_pipe
	{
		my ( $pipe, $data ) = @_;

		$log->info('|'.$$.'|'.'Write to pipe: '.$pipe.', data: '.$data);

		open  WP,'>',$pipe;
		print WP $data;
		close WP;
	}

	sub read_value
	{
		my $path = shift;

		my $v;
		open RP, $path; $v .= $_ for <RP>; close RP;

		return $v;
	}

	sub kill_pid
	{
		my ( $sig, $pid ) = @_;

		kill $sig => $pid;
	}

	sub make_directory
	{
		my ( $directory ) = @_;

		-d $directory || mkdir $directory or return 0;

		return 1;
	}

	sub locked_open
	{
		my ( $path ) = @_;

		if ( sysopen OL, $path, O_WRONLY|O_CREAT|O_TRUNC|O_EXCL )
		{
			flock ( OL, LOCK_EX );
			print OL $$;
			return 0;
		}
		else
		{
			open RL, $path; my $pid = <RL>; close RL;
			return $pid;
		}
	}
	sub check_exist_file
	{
		my ( $file ) = @_;

		return -f $file ? 0 : 1;
	}

	sub utf8_string
	{
		my ( $file ) = @_;

		open (my $dh, $file ) or $log->error('|'.$$.'|'.'Can`t open file: \''.$file.'\'.') and return;

		while (<$dh>)
		{
			Encode::_utf8_on($_);
			Encode::is_utf8($_,1) and next;
			$log->error('|'.$$.'|'.'File: \''.$file.'\' contains not utf8 string:'.$_.'.') and return undef;
		}
		close $dh;

		return 1;
	}

	sub check_root_project
	{
		my ( $project_root ) = @_;

		return -d $project_root ? 1 : 0;
	}

	sub uuid_validation
	{
		my ( $uuid ) = @_;

		return $uuid =~ /^[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}$/ ? 1 : 0;
	}

	sub get_dates
	{
		my $t = shift;

		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($t);

		return
		([
			$wday,
			sprintf('%02d%02d%02d',$year%100,$mon+1,$mday),
			sprintf('%02d.%02d.%02d %02d:%02d:%02d',$mday,$mon+1,$year%100,$hour,$min,$sec),
			sprintf('%04d-%02d-%02d %02d:%02d:%02d',$year+1900,$mon+1,$mday,$hour,$min,$sec),
			sprintf('%04d%02d%02d %02d:%02d:%02d',$year+1900,$mon+1,$mday,$hour,$min,$sec),
			sprintf('%04d%02d%02d',$year+1900,$mon,$mday),
			[ $hour, $mday, $mon, $year, $wday, $yday ],
		]);
	}

	sub eqq
	{
		my $cmp_q =
		{
			'v.4k.und.mp4' => 5,
			'v.fhd.und.mp4'=> 4,
			'v.hd.und.mp4' => 3,
			'v.hi.und.mp4' => 2,
			'v.nr.und.mp4' => 1,
			'v.lw.und.mp4' => 0,
			'4k' => 5,
			'fhd'=> 4,
			'hd' => 3,
			'hi' => 2,
			'nr' => 1,
			'lw' => 0,
		};
		return $cmp_q->{$_[0]};
	}

	sub encode_utf8_off
	{
		my ( $fname ) = @_;

		Encode::_utf8_off($fname);
	}

	sub encode_to_json
	{
		my ( $object ) = @_;

		my $json = encode_json($object);

		return $json ? $json : 0;
	}

	sub init_log
	{
		use Log::Log4perl;
		Log::Log4perl->init($_[0]);
	}

	sub get_line
	{
		my ( $object ) = @_;
		my ( $string );

		$string = lc ref($object) eq 'hash'
		? join( ', ', $_[1] ? sort { &{$_[1]}($a) <=> &{$_[1]}($b) } keys %$object : keys %$object )
		: join( ', ', $_[1] ? sort { &{$_[1]}($a) <=> &{$_[1]}($b) } @$object : @$object );

		return $string;
	}

	sub get_lang
	{
		my ( $code ) = @_;
		my ( $lang );

		## http://www.loc.gov/standards/iso639-2/php/code_list.php
		my $lang_table =
		{
			#!!!!!        und => "Undefined", - не должно быть, т.к. в USP проекте используется имя с языком und для исходного файла !!!!!!
			ron => "Romanian",
			ara => "Arabic",
			jpn => "Japanese",
			eng => "English",
			ita => "Italian",
			ruq => "audio_ruq",
			enq => "audio_enq",
			spq => "audio_spq",
			frq => "audio_frq",
			itq => "audio_itq",
			duq => "audio_duq",
			chq => "audio_chq",
			deq => 'audio_deq',
			cnq => 'audio_cnq',
			tuq => 'audio_tuq',
			spa => "Spanish",
			zho => "Chinese",
			fas => "Persian",
			bul => "Bulgarian",
			bld => 'audio_bld',		## for weak seeing people
			kor => "Korean",
			dan => "Danish",
			dnk => "Danish",
			kat => "Georgian",
			fre => "French",
			srp => "Serbian",
			dut => "Dutch",
			ger => "German",
			por => "Portuguese",
			kin => "Kinyarwanda",
			chi => "Chinese",
			ces => "Czech",
			cze => "Czech",
			ell => "Greek",
			tur => 'Turkish'
		};


		return $lang_table->{$code} if defined $lang_table->{$code};

		my $code_res = country_code2code($code, LOCALE_CODE_ALPHA_3, LOCALE_CODE_ALPHA_2);
		$code_res || return;
		$lang = code2language($code_res);
		$lang || return;

		return $lang;
	}

	sub fetch_russian_name
	{
		my ( $code ) = @_;

		my $lang =
		{
			rus => 'Русский',
			eng => 'Английский',
			bld => 'Тифлоаудио',
			fre => 'Французский',
			ara => 'Арабский',
			kor => 'Корейский',
			dan => 'Датский',
			dnk => 'Датский',
			ger => 'Немецкий',
			srp => 'Сербский',
			kat => 'Грузинский',
			por => 'Португальский',
			chi => 'Китайский',
			ces => 'Чешский',
			cze => 'Чешский',
			ell => 'Греческий',
			bul => 'Болгарский',
			fas => 'Фарси',
			tur => 'Турецкий',
			spa => 'Испанский',
			ita => 'Итальянский',
			ron => 'Румынский',
			zho => 'Китайский',
			jpn => 'Японский',
			ruq => "Русский 5.1",
			enq => "Английский 5.1",
			spq => "Испанский 5.1",
			frq => "Французский 5.1",
			itq => "Итальянский 5.1",
			duq => "Голландский 5.1",
			chq => "Китайский 5.1",
			deq => 'Немеций 5.1',
			dnq => 'Датский 5.1',
			tuq => 'Турецкий 5.1',
		};

		return $lang->{$code};
	}
	1;
