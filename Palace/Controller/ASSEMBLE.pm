#!/user/lib/perl
	
	package HPVF::Controller::ASSEMBLE;
	use base 'HPVF::Controller';
	use File::Glob qw|bsd_glob|;
	use FindBin qw|$Bin|;
	use feature qw|state say|;

	use lib $Bin.'/HPVF/lib';
	
	use Log::Any::Adapter;
	Log::Any::Adapter->set('+Adapter');
	use Log::Any '$log';

	our $errors;

	sub assemble_project_by_type_with_multiple_subprojects
	{
		my ( $self ) = @_;

		$self->utils(
		[
			'fetch_qualities',
			'get_line',
			'init_log',
			'check_exist_info_scene',
			'check_exist_thumbnails',
			'uuid_generation',
			'check_uuid_project',
			'eqq',
			'encode_utf8_off',
			'encode_to_json',
			'collect_thumbnails',
			'check_exist_addons',
			'make_directory',
			'locked_open',
			'check_content_addons',
			'check_content_project',
			'check_volume_up',
			'check_create_thumbnails',
			'check_scheme_thumbnails',
			'check_create_info_scene',
			'create_uuid_project',
			'check_exist_file',
			'create_uuid_subprojects',
			'create_success_project'
		]);
		&init_log($self->config()->{'logs'});

		$log->info('|'.$$.'|'.'Begin perform \'assemble_project_by_type_with_multiple_subprojects\' route.');

		$self->plugin();

		my $env = $self->env();
		my $app_dir = $self->env()->{'env'}->{'PWD'};

		MAIN:
		for my $prjdir ( @{$env->{'argv'}} )
		{
			-d $prjdir || next;


			my $pid = &locked_open($prjdir.'/'.'lock');
			$pid and $log->error('|'.$$.'|'.'Can`t run processing project: \''.$prjdir.'\', lock file: \''.$prjdir.'/'.'lock'.'\' exist and used process |'.$pid.'|'.'.')
			and $errors->{$prjdir}->{'lock'} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $!;

			-f $prjdir.'/'.'success'
			and $log->error('|'.$$.'|'.'Can`t run processing project: \''.$prjdir.'\', success status file: \''.$prjdir.'/'.'success'.'\' exist.')
			and $errors->{$prjdir}->{'success'} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $!;

			## this check necessary rewrite to conformance with new condition by creating lower qualities use by available files				|'4k','fhd','hd','hi'|
			my $project_files = &fetch_qualities($prjdir);
			my $check_required_qualities = grep { $_ ~~ $project_files } @{$self->config()->{'required_files'}} or
			{
				$log->error('|'.$$.'|'.'Absence required project files, project: '.$prjdir.', files: [ '.&get_line($self->config()->{'required_files'},'eqq').' ].')
				and $errors->{$prjdir}->{'lack_required_files'} = qq|\|$!\| \|$@\||
				and $self->config()->{'mode'} eq 'force' ? next : die $!
			};

			my $drm = 0;
			my $re1 = $self->config()->{'re_owner_in_path'};			## replace to match operator
			my $re2 = $self->config()->{'re_owner'};				## replace to match operator
			$prjdir =~ /$re1/ and $1 =~ /$re2/ and $1 ~~ $self->config()->{'drm_owners'} and $log->info('|'.$$.'|'.'Proccessing by uncodified traffic.') and $drm = 1;


			$log->info('|'.$$.'|'.'Start checks for files for project \''.$prjdir.'\'.');

			&check_content_project($prjdir)
			? ( $log->info('|'.$$.'|'.'Success check files, by project: \''.$prjdir.'\'.'))
			: ( $log->error('|'.$$.'|'.'Error by files check by project: \''.$prjdir.'\'.')
			and $errors->{$prjdir}->{'check_content_project'} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! );


			$log->info('|'.$$.'|'.'Start checks for files for project catalog: \''.$prjdir.'/addons\'.');

			if ( &check_exist_addons($prjdir) )
			{
				$log->info('|'.$$.'|'.'Success check exist \'addons\', project: '.$prjdir.'.');
			}
			else
			{
				$log->warn('|'.$$.'|'.'Error check exist \'addons\', project: '.$prjdir.'.');

				&make_directory($prjdir.'/'.'addons')
				? ( $log->info('|'.$$.'|'.'Success create directory \'addons\', by project: \''.$prjdir.'\'.'))
				: ( $log->error('|'.$$.'|'.'Error create directory \'addons\' by project: \''.$prjdir.'\'.')
				and $errors->{$prjdir}->{'exist_addons'} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! );
			}

			&check_content_addons($prjdir)
			? ( $log->info('|'.$$.'|'.'Success check content directory \'addons\', by project: \''.$prjdir.'\'.'))
			: ( $log->error('|'.$$.'|'.'Error of check content directory \'addons\' by project: \''.$prjdir.'\'.')
			and $errors->{$prjdir}->{'check_content_addons'} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! );

			$log->info('|'.$$.'|'.'End checks for files for project catalog: \''.$prjdir.'/addons\'.');

			$log->info('|'.$$.'|'.'End checks for files for project \''.$prjdir.'\'.');


			my ( $status, $store_langs, $store_durations, $store_nb_frames ) = $self->connect_plugin('FFMPEG')->set_data(
			{
				'prjdir' => $prjdir,
				'project_files' => $project_files,
				'key_frame_step'=> $self->config()->{'key_frame_step'},
				'check_key_frame_step'=> $self->config()->{'check_key_frame_step'},
				'fetch_data' => 1,
			})->check_streams_settings();
			not $status and $log->error('|'.$$.'|'.'Error check \'check stream settings\' by files [ '.&get_line($project_files,'eqq').' ], project \''.$prjdir.'\'.')
			and $errors->{$prjdir}->{'check_streams_settings'} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $!;


			&check_volume_up($self->config()->{'volume_up'}) &&
			(
				$self->connect_plugin('FFMPEG')->set_data(
				{
					'prjdir' => $prjdir,
					'project_files' => $project_files,
				})->volume_up()
				or ( $log->error('|'.$$.'|'.'Error check opportunity up volume by project files \''.$prjdir.'\'.')
				and $errors->{$prjdir}->{'up_volume'} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! )
			);


			my $converting;
			$converting = $self->connect_plugin('FFMPEG')->set_data(
			{
				'prjdir' => $prjdir,
				'project_files' => $project_files,
				'mode' => 'debug',
			})->launch_convert_video_file() and
			map {
				$log->info('|'.$$.'|'.'By project: \'', $prjdir.'\', was convert file \''.$_.'\'.')
			} grep { $store_durations->{$_} = $store_durations->{$converting->{$_}} } grep { $store_langs->{$converting->{$_}} ? $store_langs->{$_} = $store_langs->{$converting->{$_}} : 1 }
			  grep { $store_nb_frames->{$_} = $store_nb_frames->{$converting->{$_}} } grep { $project_files->{$_} = $_ } keys %$converting;


			map {
				$log->error('|'.$$.'|'.'Absence mandatory project files, project: '.$prjdir.', files: [ '.&get_line($self->config()->{'mandatory_files'},'eqq').' ].')
				and $errors->{$prjdir}->{'lack_mandatory_files'} = qq|\|$!\| \|$@\||
				and $self->config()->{'mode'} eq 'force' ? next : die $!
			} grep { not $_ ~~ $project_files } @{$self->config()->{'mandatory_files'}};


			grep { $_ ~~ $store_durations } @{$self->config()->{'mandatory_files'}} or
			{
				$log->error('|'.$$.'|'.'Error fetching \'duration\' by required project files, project: '.$prjdir.' files: [ '.&get_line($self->config()->{'mandatory_files'},'eqq').' ]') and
				$errors->{$prjdir}->{'fetch_durations'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			grep { $_ ~~ $store_nb_frames } @{$self->config()->{'mandatory_files'}} or
			{
				$log->error('Error fetching \'nb_frames\' by required project files, project: '.$prjdir.' files: [ '.&get_line($self->config()->{'mandatory_files'},'eqq').' ]') and
				$errors->{$prjdir}->{'fetch_nb_frames'} = qq|\|$!\| \|$@\|| and
				$elf->config()->{'mode'} eq 'force' ? next : die $!
			};


			&check_create_thumbnails($self->config()->{'create_thumbnails'}) and
			$self->connect_plugin('FFMPEG')->set_data(
			{
				'prjdir' => $prjdir,
				'source' => $self->config()->{'mandatory_files'}->[0],
				'nb_frames' => $store_nb_frames->{$self->config()->{'mandatory_files'}->[0]},
			})->create_thumbnails()
			? ( $log->info('|'.$$.'|'.'By project: ', $prjdir. ', was create \'thumbnails\'.') )
			: ( $error->info('|'.$$.'|'.'Error create \'thumbnails\' by project '.$prjdir.'.') and $errors->{$prjdir}->{'create_thumbnails'} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! );


			&check_scheme_thumbnails($self->config()->{'scheme_thumbnails'}) and
			$self->connect_plugin('FFMPEG')->set_data(
			{
				'prjdir' => $prjdir,
				'source' => $self->config()->{'mandatory_files'}->[0],
			})->create_scheme_thumbnails()
			? ( $log->info('|'.$$.'|'.'By project: ', $prjdir. ', was create \'scheme thumbnails\'.') )
			: ( $error->info('|'.$$.'|'.'Error create \'scheme thumbnails\' by project '.$prjdir.'.') and $errors->{$prjdir}->{'scheme_thumbnails'} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! );

			my $thumbnails = &collect_thumbnails($prjdir)
			|| ( $log->error('By current project: '.$prjdir.', don`t collected \'thumbnails\' !') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! );


			&check_create_info_scene($self->config()->{'create_info_scene'}) and
			{
				$store_durations->{$self->config()->{'mandatory_files'}->[0]} > $self->config()->{'min_duration'}
				? $self->connect_plugin('FFMPEG')->set_data(
				  {
					'prjdir' => $prjdir,
					'source' => $project_files->{$self->config()->{'mandatory_files'}->[0]},
				  })->create_info_scene()
				? ( $log->info('|'.$$.'|'.'By project: \'', $prjdir.'\', was create \'info.scene\'.') )
				: (
				    $log->error('|'.$$.'|'.'Error create \'info.scene\' by project \''.$prjdir.'\'.') and
				    $errors->{$prjdir}->{'create_info_scene'} = qq|\|$!\| \|$@\|| and
			            $self->config()->{'mode'} eq 'force' ? next : die $!
			          )
				: $log->warn('|'.$$.'|'.'Generation of \'info.scene\' disabled or content duration less then or equal '.
				  $self->config()->{'min_duration'}.' sec. File info.scene will not be created. '.'|'.
				  $store_durations->{$self->config()->{mandatory_files}->[0]} .' > '. $self->config()->{'min_duration'}.'|')
			};


			$drm or
			{
				$self->connect_plugin('MP4SPLIT')->set_data(
				{
					'prjdir' => $prjdir,
					'project_files' => $project_files,
					'store_langs' => $store_langs
				})->create_pdl()
				? (
				    $log->info('|'.$$.'|'.'By project files: [ '. &get_line({map {$_ => $project_files_{$_}} grep {/^v\.(hd|hi|nr|lw)\.und\.mp4$/} keys %$project_files},'eqq'). ' ], project: '.
				    $prjdir.', was create pdl files.')
				  )
				: (
				    $log->error('|'.$$.'|'.'Create error by project files: [ '. &get_line({map {$_ => $project_files_{$_}} grep {/^v\.(hd|hi|nr|lw)\.und\.mp4$/} keys %$project_files}). ' ] project: '.
				    $prjdir.', pdl files.') and
				    $errors->{$prjdir}->{'create_pdl'} = qq|\|$!\| \|$@\|| and
				    $self->config()->{'mode'} eq 'force' ? next : die $!
				  )
			};

			my $main_uuid;
			! &check_exist_file($prjdir.'/'.'0AVProjectAlias')
			? {
			    $log->warn('|'.$$.'|'.'File \''.$prjdir.'/'.'0AVProjectAlias\' already exist.') and
			    $main_uuid = &check_uuid_project($prjdir) or
			    (
			      $log->error('|'.$$.'|'.'By current project: '.$prjdir.', lack \'uuid\' or \'uuid\' not valid!') and
			      $errors->{$prjdir}->{'check_uuid_project'} = qq|\|$!\| \|$@\|| and
			      $self->config()->{'mode'} eq 'force' ? next : die $!
			    )
			  }
			: {
			    $log->info('|'.$$.'|'.'Create \''.$prjdir.'/'.'/0AVProjectAlias\' file.') and
			    $main_uuid = &uuid_generation() and &create_uuid_project($prjdir,$main_uuid) or
			    (
                               $log->error('|'.$$.'|'.'Can\'t create \''.$prjdir.'/'.'0AVProjectAlias\' file: '.$!) and
			       $errors->{$prjdir}->{'create_uuid_project'} = qq|\|$!\| \|$@\|| and
			       $self->config()->{'mode'} eq 'force' ? next : die $!
			    )
			  };


			my ( $uuid_subprojects );
			for my $file ( sort { eqq($b) <=> eqq($a) } keys %$project_files )
			{
				$self->config()->{'match_qualities_numeric'}->{$self->config()->{'alias_qualities'}->{$file}} >= $self->config()->{'subprojects_level'}->[0] &&
				$self->config()->{'match_qualities_numeric'}->{$self->config()->{'alias_qualities'}->{$file}} <= $self->config()->{'subprojects_level'}->[-1]|| next;


				my $uuid = &uuid_generation();
				$uuid_subprojects->{$main_uuid}->{$self->config()->{'alias_qualities'}->{$file}} = $uuid;

				$log->info('|'.$$.'|'.'Create \''.$prjdir.'/'.$uuid.'.ssm\' directory.');
				mkdir $prjdir.'/'.$uuid.'.ssm' or
				(
					$log->error('|'.$$.'|'.'Can\'t create \''.$prjdir.'/'.$uuid.'.ssm\' directory: '.$!) and
					$errors->{$prjdir}->{'create_ssm'} = qq|\|$!\| \|$@\|| and
					$self->config()->{'mode'} eq 'force' ? next MAIN : die $!
				);


				$log->info('|'.$$.'|'.'Create \''.$prjdir.'/'.$uuid.'.ssm/0AVProjectAlias\' file.');
				&create_uuid_project($prjdir.'/'.$uuid.'.ssm',$uuid) ||
				(
					$log->error('|'.$$.'|'.'Can\'t create \''.$prjdir.'/'.'0AVProjectAlias\' file: '.$!) and
					$errors->{$prjdir}->{'create_uuid_project'} = qq|\|$!\| \|$@\|| and
					$self->config()->{'mode'} eq 'force' ? next MAIN : die $!
				);


				&check_uuid_project($prjdir.'/'.$uuid.'.ssm') ||
				(
					$log->error('|'.$$.'|'.'By creating project: '.$prjdir.'/'.$uuid.'.ssm'.', lack \'uuid\' or \'uuid\' not valid!') and
					$errors->{$prjdir}->{'check_uuid_project'} = qq|\|$!\| \|$@\|| and
					$self->config()->{'mode'} eq 'force' ? next MAIN : die $!
				);


				$self->connect_plugin('MP4SPLIT')->set_data(
				{
					'prjdir' => $prjdir,
					'prj_id' => $uuid,
					'drm' => $drm ? 1 : 0,
					'run_check_key_frame_step' => 1,
					'project_files' => $project_files
				})->create_ism()
				? ( $log->info('|'.$$.'|'.'Success create \'ism manifest\', by project: '.$prjdir.'/'.$uuid.'.ssm !') )
				: ( $log->error('|'.$$.'|'.'Error create \'ism manifest\', by project: '.$prjdir.'/'.$uuid.'.ssm') and
				    $errors->{$prjdir}->{'create_ism'} = qq|\|$!\| \|$@\|| and
				    $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );


				$log->info('|'.$$.'|'.'Creating necessary links for subproject: \''.$prjdir.'/'.$uuid.'.ssm\' to required files for PDL and required source files.');

				my @infilelist;
				map { push @infilelist, $_ } grep { -f $prjdir.'/'.$_ } grep { $_ ~~ $self->config()->{'available_qualities'} } keys %$project_files;


				chdir($prjdir.'/'.$uuid.'.ssm') or
				(
				     $log->error('|'.$$.'|'.'Can not replace to directory '.$prjdir.'/'.$uuid.'.ssm')
				     and $errors->{$prjdir}->{'replace_to_dir'} = qq|\|$!\| \|$@\||
				     and $self->config()->{'mode'} eq 'force' ? next MAIN : die $!
				);


				for my $infile ( @infilelist )
				{
					symlink('..'.'/'.$infile, $infile) or
					(
						$log->error('|'.$$.'|'.'Can\'t create symlinks for source files: '.$infile.', by subproject: '.$prjdir.'/'.$uuid.'.ssm !')
						and $errors->{$prjdir}->{'create_symlink'} = qq|\|$!\| \|$@\||
						and $self->config()->{'mode'} eq 'force' ? next MAIN : die $!
					);

					$drm == 1 and next;
					$infile =~ /^v\.(fhd|4k)\.und\.mp4$/ and next;

					my ($v, $prf, $lng, $ext) = split /\./, $infile;
					foreach my $lang (keys%{$store_langs->{$infile}})
					{
						my $fname = "$v.$prf.".$lang.".$ext";
						&encode_utf8_off($fname);
						-e $prjdir.'/'.$fname or
						(
							$log->error('|'.$$.'|'.'File \''.$prjdir.'/'.$fname.'\' not exist!')
							and $errors->{$prjdir}->{'lack_file'} = qq|\|$!\| \|$@\||
							and $self->config()->{'mode'} eq 'force' ? next MAIN : die $!
						);
						-e $prjdir.'/'.$uuid.'.ssm/'.$fname and $log->warn('|'.$$.'|'.'Symlink \''.$prjdir.'/'.$uuid.'.ssm/'.$fname.'\' already exist.');

						symlink('..'.'/'.$fname, $fname) or
						(
							$log->error('|'.$$.'|'.'Can\'t create symlinks for source files: \''.$prjdir.'/'.$fname.' => '.$prjdir.'/'.$uuid.'.ssm/'.$fname.'\' !')
							and $errors->{$prjdir}->{'create_symlink'} = qq|\|$!\| \|$@\||
							and $self->config()->{'mode'} eq 'force' ? next MAIN : die $!
						);
					}

					if ( -f $prjdir.'/'.'v.hi.und.mp4' )
					{
						if ( -f $prjdir.'/'.'v.hi.rus.mp4' )
						{
							symlink('..'.'/'.'v.hi.rus.mp4', 'v.mp4');
						}
						elsif ( -f $prjdir.'/'.'v.hi.eng.mp4' )
						{
							symlink('..'.'/'.'v.hi.eng.mp4', 'v.mp4');
						}
						else
						{
							for ( bsd_glob $prjdir.'/'.'v.hi.???.mp4' )
							{
								/v.hi.und.mp4/ and next;
								symlink('../'.(split(/\//,$_))[-1], 'v.mp4');
							}
						}
						-f $prjdir.'/'.$uuid.'.ssm/v.mp4' or $self->config()->{'streams'} ne 'all' or
						(
							$log->error('|'.$$.'|'.'Can`t create default video file \''.$prjdir.'/'.$uuid.'.ssm/v.mp4\' .')
							and $errors->{$prjdir}->{'create_mp4'} = qq|\|$!\| \|$@\||
							and $self->config()->{'mode'} eq 'force' ? next MAIN : die $!
						);
					}
				}


				$log->info('|'.$$.'|'.'Create \''.$prjdir.'/'.$uuid.'.ssm/addons\' directory.');
				-d $prjdir.'/'.$uuid.'.ssm'.'/'.'addons' or mkdir $prjdir.'/'.$uuid.'.ssm'.'/'.'addons' or
				(
					$log->error('|'.$$.'|'.'Can\'t create \''.$prjdir.'/'.$uuid.'.ssm/addons\' directory: '.$!) and
					$errors->{$prjdir}->{'create_addons'} = qq|\|$!\| \|$@\|| and
					$self->config()->{'mode'} eq 'force' ? next MAIN : die $!
				);


				$log->info('|'.$$.'|'.'Create \''.$prjdir.'/'.$uuid.'.ssm/addons/srt\' links.');
				for (bsd_glob($prjdir.'/addons/*.srt'))
				{
					/\/([a-z\.]+)$/;
					-f $_ and ! -f $prjdir.'/'.$uuid.'.ssm/'.'addons/'.$1
					and $log->info('|'.$$.'|'.'Create \''.$prjdir.'/'.$uuid.'.ssm/addons/'.$1.'\' link.')
					and symlink('../../addons/'.$1, $prjdir.'/'.$uuid.'.ssm'.'/'.'addons/'.$1);
				}

				$log->info('|'.$$.'|'.'Create \''.$prjdir.'/'.$uuid.'.ssm/addons/vtt\' links.');
				for (bsd_glob($prjdir.'/addons/*.vtt'))
				{
					/\/([a-z\.]+)$/;
					-f $_ and ! -f $prjdir.'/'.$uuid.'.ssm/'.'addons/'.$1
					and $log->info('|'.$$.'|'.'Create \''.$prjdir.'/'.$uuid.'.ssm/addons/'.$1.'\' link.')
					and symlink('../../addons/'.$1, $prjdir.'/'.$uuid.'.ssm'.'/'.'addons/'.$1);
				}


				chdir( $app_dir ) ||
				(
					$log->error('|'.$$.'|'.'Cant not backward replace to application directory: '.$app_dir.'!')
					and $errors->{$prjdir}->{'replace_to_dir'} = qq|\|$!\| \|$@\||
					and $self->config()->{'mode'} eq 'force' ? next MAIN : die $!
				);


				$log->info('|'.$$.'|'.'Create \''.$prjdir.'/'.$uuid.'.ssm/addons/info.xml\'.');
				open INFOXML, '>', $prjdir.'/'.$uuid.'.ssm'.'/'.'addons/info.xml' or
				(
					$log->error('|'.$$.'|'.'Can\'t open required file \''.$prjdir.'/'.$uuid.'.ssm/addons/info.xml\' '.$!)
					and $errors->{$prjdir}->{'open_info_xml'} = qq|\|$!\| \|$@\||
					and $self->config()->{'mode'} eq 'force' ? next MAIN : die $!
				);

				my $info_xml;
				$info_xml = $self->connect_plugin('FFMPEG')->set_value('prjdir' => $prjdir.'/'.$uuid.'.ssm')->create_info_xml();
				$info_xml and print INFOXML $info_xml or
				(
					$log->error('|'.$$.'|'.'Error create \'info.xml\' by subproject: '.$prjdir.'/'.$uuid.'.ssm !')
					and $errors->{$prjdir}->{'create_info_xml'} = qq|\|$!\| \|$@\||
					and $self->config()->{'mode'} eq 'force' ? next MAIN : die $!
				);
				close INFOXML;


				$log->info('|'.$$.'|'.'Create \'thumbnails\' links by subproject.');
				for ( keys %$thumbnails )
				{
					-f $prjdir.'/'.'addons'.'/'.$_ and symlink('../..'.'/'.'addons'.'/'.$_, $prjdir.'/'.$uuid.'.ssm'.'/'.'addons'.'/'.$_);
				}


				$log->info('|'.$$.'|'.'Create \''.$prjdir.'/'.$uuid.'.ssm/addons/info_scene\' link.');
				-f $prjdir.'/'.'addons/info.scene' and symlink('../..'.'/'.'addons/info.scene', $prjdir.'/'.$uuid.'.ssm'.'/'.'addons/info.scene');

				delete($project_files->{$file});
			}

			$log->info('|'.$$.'|'.'Create uuid and video files conformance list, by project \''.$prjdir.'\'.');
			&create_uuid_subprojects($prjdir,$uuid_subprojects) or
			{
				$log->error('|'.$$.'|'.'Can not create uuid and video files conformance list \''.$prjdir.'/'.'uuid_subprojects\'.') and
				$errors->{$prjdir}->{'create_uuid_subprojects'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			$log->info('|'.$$.'|'.'Create success file by project \''.$prjdir.'\'.');
			&create_success_project($prjdir) or
			{
				$log->error('|'.$$.'|'.'Can not create success file by project \''.$prjdir.'\'') and
				$errors->{$prjdir}->{'create_success_project'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			unlink bsd_glob $prjdir.'/*.mbtree';
			unlink bsd_glob $prjdir.'/*.log';
			unlink $prjdir.'/'.'lock';
		}

		$log->info('|'.$$.'|'.'End perform \'assemble_project_by_type_with_multiple_subprojects\' route.');
	}

	sub move_2_home_project
	{
		my ( $self ) = @_;


		$self->utils(
		[
			'get_line',
			'read_dir',
			'check_exist_file',
			'check_exist_info_scene',
			'check_uuid_project',
			'eqq',
			'change_substr_file',
			'change_uid',
			'create_path',
			'move_file',
			'change_permissions',
			'init_log'
		]);

		&init_log($self->config()->{'logs'});

		$log->info('|'.$$.'|'.'Begin perform \'move_2_home_project\' route.');

		$self->plugin();

		my $env = $self->env();
		my $app_dir = $self->env()->{'env'}->{'PWD'};

		MAIN:
		for my $prjdir ( @{$env->{'argv'}} )
		{
			$log->info('|'.$$.'|'.'Start move project \''.$prjdir.'\' to home directory.');

			-d $prjdir or
			{
				$log->error('|'.$$.'|'.'Parameter prjdir \''.$prjdir.'\' must be directory.') and
				$errors->{$prjdir}->{'check_directory'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			not &check_exist_file($prjdir.'/'.'success') or
			{
				$log->error('|'.$$.'|'.'Project \''.$prjdir.'\' must contain \'success\' file.') and
				$errors->{$prjdir}->{'check_exist_success'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			my $o;
			$o = $self->config()->{'re_owner_in_path'} and $prjdir =~ /$o/;
			( ($self->config()->{'owners_accord'}->{$1} or $1) ~~ $self->config()->{'owners'} ) or
			{
				$log->error('|'.$$.'|'.'By path \''.$prjdir.'\', absence allowable owner!') and
				$errors->{$prjdir}->{'check_allowable_owner_by_path'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!

			};
			my $tar_dir = $self->config()->{'srcbasedir'}.'/'.($self->config()->{'owners_accord'}->{$1}||$1);

			my $p;
			$p = $self->config()->{'re_prj'} and $prjdir =~ /$p/;
			$1 ne $prjdir and -d $1 or
			{
				$log->error('|'.$$.'|'.'Path to project: \''.$prjdir.'\', not conformance required type path!') and
				$errors->{$prjdir}->{'check_accord_path_to_prjdir'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};
			my $cur_dir = $1;
			my $tail = $2;


			my $re = $self->config()->{'re_ssm'};
			for ( bsd_glob($prjdir.'/*.ssm') )
			{
				/$re/ or
				{
					$log->error('|'.$$.'|'.'Finded matching don\`t according type \'uuid\' directory by mainproject: \''.$prjdir.'\' subproject: \''.$_.'\'') and
					$errors->{$prjdir}->{'check_accord_ssm_by_uuid'} = qq|\|$!\| \|$@\|| and
					$self->config()->{'mode'} eq 'force' ? next MAIN : die $!
				};

				my $uuid = $1;

				&check_uuid_project($prjdir.'/'.$uuid.'.ssm') ||
				(
					$log->error('|'.$$.'|'.'By creating project: '.$prjdir.'/'.$uuid.'.ssm'.', lack \'uuid\' or \'uuid\' not valid!') and
					$errors->{$prjdir}->{'check_uuid_project'} = qq|\|$!\| \|$@\|| and
					$self->config()->{'mode'} eq 'force' ? next MAIN : die $!
				);

				not &check_exist_file($prjdir.'/'.$uuid.'.ssm'.'/'.$uuid.'.ism') or
				{
					$log->error('|'.$$.'|'.'Subproject \''.$prjdir.'/'.$uuid.'.ssm'.'\' must contain \'ism\' file.') and
					$errors->{$prjdir}->{'check_exist_ism'} = qq|\|$!\| \|$@\|| and
					$self->config()->{'mode'} eq 'force' ? next MAIN : die $!
				};

				&change_substr_file($_.'/'.$uuid.'.ism',$cur_dir,$tar_dir) or
				{
					$log->error('|'.$$.'|'.'Can\'t change all substrings contained paths in \'ism\' file, by subproject \''.$prjdir.'/'.$uuid.'.ssm'.'\'.') and
					$errors->{$prjdir}->{'change_substr_file'} = qq|\|$!\| \|$@\|| and
					$self->config()->{'mode'} eq 'force' ? next MAIN : die $!
				};
			}

			my $read_dir = &read_dir();$read_dir->($prjdir);
			map { &change_uid($self->config()->{'uid'},$self->config()->{'gid'},$_) } grep { -d and chmod $self->config()->{'permissions_dir'}, $_ or chmod $self->config()->{'permissions_file'}, $_} @{$read_dir->()};

			my $dir = $tar_dir.$tail;

			-d $dir or
			(
				&create_path($dir) or
				$log->error('|'.$$.'|'.'Can\'t create target directory \''.$dir.'\'.') and
				$errors->{$prjdir}->{'create_target_dir'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			);

			&move_file($prjdir,$dir) or
			{
				$log->error('|'.$$.'|'.'Can\'t move project to target directory \''.$dir.'\'.') and
				$errors->{$prjdir}->{'move_to_target_dir'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			$log->info('|'.$$.'|'.'Complited move project \''.$prjdir.'\' to home directory.');
		}
		$log->info('|'.$$.'|'.'End perform \'move_2_home_project\' route.');
	}

	sub unpublish_project
	{
		my ( $self ) = @_;

		$self->utils(
		[
			'init_log',
			'get_line',
			'check_exist_file'
		]);

		&init_log($self->config()->{'logs'});

		$log->info('|'.$$.'|'.'Begin perform \'unpublish_project\' route.');

		$self->plugin();

		my $env = $self->env();
		my $app_dir = $self->env()->{'env'}->{'PWD'};

		my $re = $self->config()->{'re_ssm'};

		MAIN:
		for my $prjdir ( @{$env->{'argv'}} )
		{
			$log->info('|'.$$.'|'.'Start remove symlinks for publish project \''.$prjdir.'\'.');

			-d $prjdir or
			{
				$log->error('|'.$$.'|'.'Parameter prjdir \''.$prjdir.'\' must be directory.') and
				$errors->{$prjdir}->{'check_directory'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			not &check_exist_file($prjdir.'/'.'success') or
			{
				$log->error('|'.$$.'|'.'Project \''.$prjdir.'\' must contain \'success\' file.') and
				$errors->{$prjdir}->{'check_exist_success'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			my $o;
			$o = $self->config()->{'re_owner_in_path'} and $prjdir =~ /$o/ and
			$1 ~~ $self->config()->{'owners'} or
			{
				$log->error('|'.$$.'|'.'By path \''.$prjdir.'\', absence allowable owner!') and
				$errors->{$prjdir}->{'check_allowable_owner_by_path'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!

			};

			my $pub_dir = $self->config()->{'pubdir'}.'/'.$1;
			-d $pub_dir or
			{
				$log->error('|'.$$.'|'.'Publish directory \''.$pub_dir.'\' not exist.') and
				$errors->{$prjdir}->{'check_exist_publish_dir'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			my $pub_add = $pub_dir.'/'.'addons';
			-d $pub_add or
			{
				$log->error('|'.$$.'|'.'Publish directory \''.$pub_add.'\' not exist.') and
				$errors->{$prjdir}->{'check_exist_publish_addons'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			my $pub_str = $pub_dir.'/'.'stream';
			-d $pub_str or
			{
				$log->error('|'.$$.'|'.'Publish directory \''.$pub_str.'\'.') and
				$errors->{$prjdir}->{'check_exist_publish_stream'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			opendir RD, $prjdir;
			for ( readdir RD )
			{
				if ( /$re/ )
				{
					! -l $pub_str.'/'.$1.'.ssm'
					? $log->warn('|'.$$.'|'.'Not published stream catalog for subproject \''.$1.'.ssm'.'\', by project \''.$prjdir.'\'.')
					: (
						$log->info('|'.$$.'|'.'Unlink published stream catalog for subproject \''.$1.'.ssm'.'\', by project \''.$prjdir.'\'.') and
						unlink $pub_str.'/'.$1.'.ssm' or
						$log->error('|'.$$.'|'.'Can\'t remove symlink by stream catalog for subproject \''.$1.'.ssm'.'\', by project \''.$prjdir.'\'.') and
						$errors->{$prjdir}->{'remove_stream_symlink'} = qq|\|$!\| \|$@\|| and
						$self->config()->{'mode'} eq 'force' ? next MAIN : die $!
					  )
					;

					! -l $pub_add.'/'.$1
					? $log->warn('|'.$$.'|'.'Not published addons catalog for subproject \''.$1.'.ssm'.'\', by project \''.$prjdir.'\'.')
					: (
						$log->info('|'.$$.'|'.'Unlink published addons catalog for subproject \''.$1.'.ssm'.'\', by project \''.$prjdir.'\'.') and
						unlink $pub_add.'/'.$1 or
						$log->error('|'.$$.'|'.'Can\'t remove symlink by addons catalog for subproject \''.$1.'.ssm'.'\', by project \''.$prjdir.'\'.') and
						$errors->{$prjdir}->{'remove_addons_symlink'} = qq|\|$!\| \|$@\|| and
						$self->config()->{'mode'} eq 'force' ? next MAIN : die $!
					  )
					;
				}
			}
			closedir RD;

			$log->info('|'.$$.'|'.'Complited remove symlinks for publish project \''.$prjdir.'\'.');
		}
		$log->info('|'.$$.'|'.'End perform \'unpublish_project\' route.');
	}

	sub publish_project
	{
		my ( $self ) = @_;

		$self->utils(
		[
			'get_line',
			'read_dir',
			'check_exist_file',
			'check_exist_info_scene',
			'check_uuid_project',
			'eqq',
			'change_substr_file',
			'change_uid',
			'create_path',
			'move_file',
			'change_permissions',
			'init_log'
		]);

		&init_log($self->config()->{'logs'});

		$log->info('|'.$$.'|'.'Begin perform \'publish_project\' route.');

		$self->plugin();

		my $env = $self->env();
		my $app_dir = $self->env()->{'env'}->{'PWD'};

		my $re = $self->config()->{'re_ssm'};

		MAIN:
		for my $prjdir ( @{$env->{'argv'}} )
		{
			$log->info('|'.$$.'|'.'Start create required symlinks for publish project \''.$prjdir.'\'.');

			-d $prjdir or
			{
				$log->error('|'.$$.'|'.'Parameter prjdir \''.$prjdir.'\' must be directory.') and
				$errors->{$prjdir}->{'check_directory'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			not &check_exist_file($prjdir.'/'.'success') or
			{
				$log->error('|'.$$.'|'.'Project \''.$prjdir.'\' must contain \'success\' file.') and
				$errors->{$prjdir}->{'check_exist_success'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			my $o;
			$o = $self->config()->{'re_owner_in_path'} and $prjdir =~ /$o/ and
			$1 ~~ $self->config()->{'owners'} or
			{
				$log->error('|'.$$.'|'.'By path \''.$prjdir.'\', absence allowable owner!') and
				$errors->{$prjdir}->{'check_allowable_owner_by_path'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!

			};


			my $pub_dir = $self->config()->{'pubdir'}.'/'.$1;
			-d $pub_dir or
			{
				&create_path($pub_dir) or
				$log->error('|'.$$.'|'.'Can\'t create publish directory \''.$pub_dir.'\'.') and
				$errors->{$prjdir}->{'create_publish_dir'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			my $pub_add = $pub_dir.'/'.'addons';
			-d $pub_add or
			{
				mkdir($pub_add) or
				$log->error('|'.$$.'|'.'Can\'t create publish directory \''.$pub_add.'\'.') and
				$errors->{$prjdir}->{'create_publish_addons'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			my $pub_str = $pub_dir.'/'.'stream';
			-d $pub_str or
			{
				mkdir($pub_str) or
				$log->error('|'.$$.'|'.'Can\'t create publish directory \''.$pub_str.'\'.') and
				$errors->{$prjdir}->{'create_publish_stream'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			opendir RD, $prjdir;
			for ( readdir RD )
			{
				if ( /$re/ )
				{
					-f $prjdir.'/'.$1.'.ssm'.'/'.'0AVProjectAlias' or
					{
						$log->error('|'.$$.'|'.'Not finded \'0AVProjectAlias\' file, for subproject \''.$1.'.ssm'.'\', by project \''.$prjdir.'\'.') and
						$errors->{$prjdir}->{'check_exist_0AVProjectAlias'} = qq|\|$!\| \|$@\|| and
						$self->config()->{'mode'} eq 'force' ? next MAIN : die $!
					};

					-l $pub_str.'/'.$1.'.ssm'
					? $log->warn('|'.$$.'|'.'Already was published stream catalog for subproject \''.$1.'.ssm'.'\', by project \''.$prjdir.'\'.')
					: (
						$log->warn('|'.$$.'|'.'Not exist published stream catalog for subproject \''.$1.'.ssm'.'\', by project \''.$prjdir.'\'.') and
						symlink $prjdir.'/'.$1.'.ssm', $pub_str.'/'.$1.'.ssm' or
						$log->error('|'.$$.'|'.'Can\'t create symlink by stream catalog for subproject \''.$1.'.ssm'.'\', by project \''.$prjdir.'\'.') and
						$errors->{$prjdir}->{'create_stream_symlink'} = qq|\|$!\| \|$@\|| and
						$self->config()->{'mode'} eq 'force' ? next MAIN : die $!
					  )
					;

					-l $pub_add.'/'.$1
					? $log->warn('|'.$$.'|'.'Already was published addons catalog for subproject \''.$1.'.ssm'.'\', by project \''.$prjdir.'\'.')
					: (
						$log->warn('|'.$$.'|'.'Not exist published addons catalog for subproject \''.$1.'.ssm'.'\', by project \''.$prjdir.'\'.') and
						symlink $prjdir.'/'.$1.'.ssm'.'/addons', $pub_add.'/'.$1 or
						$log->error('|'.$$.'|'.'Can\'t create symlink by addons catalog for subproject \''.$1.'.ssm'.'\', by project \''.$prjdir.'\'.') and
						$errors->{$prjdir}->{'create_addons_symlink'} = qq|\|$!\| \|$@\|| and
						$self->config()->{'mode'} eq 'force' ? next MAIN : die $!
					  )
					;
				}
			}
			close RD;

			$log->info('|'.$$.'|'.'Complited create required symlinks for publish project \''.$prjdir.'\'.');
		}
		$log->info('|'.$$.'|'.'End perform \'publish_project\' route.');
	}

	sub synchronization_project
	{
		my ( $self ) = @_;

		$self->utils(
		[
			'init_log',
			'check_exist_file'
		]);

		&init_log($self->config()->{'logs'});

		$log->info('|'.$$.'|'.'Begin perform \'synchronization_project\' route.');

		$self->plugin();

		my $env = $self->env();
		my $app_dir = $self->env()->{'env'}->{'PWD'};

		my $re = $self->config()->{'re_ssm'};

		MAIN:
		for my $prjdir ( @{$env->{'argv'}} )
		{
			$log->info('|'.$$.'|'.'Start synchronization project \''.$prjdir.'\'.');

			-d $prjdir or
			{
				$log->error('|'.$$.'|'.'Parameter prjdir \''.$prjdir.'\' must be directory.') and
				$errors->{$prjdir}->{'check_directory'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			not &check_exist_file($prjdir.'/'.'success') or
			{
				$log->error('|'.$$.'|'.'Project \''.$prjdir.'\' must contain \'success\' file.') and
				$errors->{$prjdir}->{'check_exist_success'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			my $o;
			$o = $self->config()->{'re_owner_in_path'} and $prjdir =~ /$o/ and
			$1 ~~ $self->config()->{'owners'} or
			{
				$log->error('|'.$$.'|'.'By path \''.$prjdir.'\', absence allowable owner!') and
				$errors->{$prjdir}->{'check_allowable_owner_by_path'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};


			$self->connect_plugin('RSYNC')->set_data(
			{
				'prjdir' => $prjdir,
				'owner' => $1,
				'mode' => 'force',
#				'mode' => 'debug'
			})->sync_main_project() && ( $log->error('Can not perform synchronization all by mainproject: '.$prjdir.' to remote servers: [ '.&get_line($self->config()->{'syncserver'}).' ].')
			and $errors->{$prjdir}->{'sync_main_project'} = qq|\|$!\| \|$@\||
			and $self->config()->{'mode'} eq 'force' ? next : die $! );

			$log->info('|'.$$.'|'.'Complited synchronization project \''.$prjdir.'\'.');
		}

		$log->info('|'.$$.'|'.'End perform \'synchronization_project\' route.');
	}

	sub rename_sources_files
	{
		my ( $self ) = @_;

		$self->utils(
		[
			'init_log',
			'get_line',
			'rename_source_files',
			'check_exist_file'
		]);

		&init_log($self->config()->{'logs'});

		$log->info('|'.$$.'|'.'Begin perform \'rename_source_files\' route.');

		$self->plugin();

		my $env = $self->env();
		my $app_dir = $self->env()->{'env'}->{'PWD'};

		MAIN:
		for my $source ( @{$env->{'argv'}} )
		{
			$log->info('|'.$$.'|'.'Start rename files by source \''.$source.'\'.');

			&rename_source_files($source) or
			{
				$log->error('|'.$$.'|'.'Not success perform rename files by source \''.$source.'\'.') and
				$errors->{$source}->{'rename_source_files'} = qq|\|$!\| \|$@\|| and
				$self->config()->{'mode'} eq 'force' ? next : die $!
			};

			map {
				$log->info('|'.$$.'|'.'Complited rename files by source \''.$source.'\'.') and next;
			} grep { -f $source.'/'.$_ } @{$self->config()->{'required_files'}};

			$log->error('|'.$$.'|'.'Absence at least one file from required files['.&get_line({map {$_=>$_} @{$self->config()->{'required_files'}}}, 'eqq').'] for begin creating project.');
			$errors->{$source}->{'check_required_files'} = qq|\|$!\| \|$@\||;
			$self->config()->{'mode'} eq 'force' ? next : die $!;
		}

		$log->info('|'.$$.'|'.'End perform \'rename_source_files\' route.');
	}

	sub re_assemble_project_to_multiple_subprojects
	{
		my ( $self ) = @_;



		$self->utils(
		[
			'fetch_qualities',
			'get_line',
			'check_exist_info_scene',
			'check_exist_thumbnails',
			'uuid_generation',
			'check_uuid_project',
			'eqq',
			'encode_utf8_off',
			'encode_to_json',
			'collect_thumbnails',
			'check_exist_addons',
			'make_directory',
			'init_log',
		]);

		&init_log($self->config()->{'logs'});

		$log->info('Begin perform \'reassemble_prjoject_to_multiple_subprojects\' route.');

		$self->plugin();

		my $env = $self->env();
		my $app_dir = $self->env()->{'env'}->{'PWD'};

		MAIN:
		for my $prjdir ( @{$env->{'argv'}} )
		{
			-d $prjdir || next;
			my $project_files = &fetch_qualities($prjdir);

			map {
				$log->error('Absence required project files, project: '.$prjdir.', files: [ '.&get_line($self->config()->{'mandatory_files'},'eqq').' ]')
				and $errors->{$prjdir} = qq|\|$!\| \|$@\||
				and $self->config()->{'mode'} eq 'force' ? next : die $!
			} grep { not $_ ~~ $project_files } @{$self->config()->{'mandatory_files'}};


			my $store_langs = $self->connect_plugin('FFMPEG')->set_data(
			{
				'prjdir' => $prjdir,
				'project_files' => $project_files,
				'mode' => $self->config()->{'mode'}
			})->fetch_soundtracks_project();

			$store_langs
			? ( $log->info('By project files: [ '. &get_line($project_files,'eqq'). ' ], project: '. $prjdir. ', was fetch list soundtracks.') )
			: ( $log->error('Fetch error by project files: [ '. &get_line($project_files). ' ] project: '. $prjdir. ', list soundtracks.') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $!);


			if ( $prjdir !~ /tvzavr_d/ )
			{
				my $response = $self->connect_plugin('MP4SPLIT')->set_data(
				{
					'prjdir' => $prjdir,
					'project_files' => $project_files,
					'store_langs' => $store_langs
				})->create_pdl();

				$response
				? ( $log->info('By project files: [ '. &get_line({map {$_ => $project_files_{$_}} grep {/^v\.(hd|hi|nr|lw)\.und\.mp4$/} keys %$project_files},'eqq'). ' ], project: '. $prjdir. ', was create pdl files.') )
				: ( $log->error('Create error by project files: [ '. &get_line({map {$_ => $project_files_{$_}} grep {/^v\.(hd|hi|nr|lw)\.und\.mp4$/} keys %$project_files}). ' ] project: '. $prjdir. ', pdl files.')
				and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! );
			}


			if ( &check_exist_addons($prjdir) )
			{
				$log->info('Success check \'addons\', project: '.$prjdir.'.');
			}
			else
			{
				$log->warn('Error check \'addons\', project: '.$prjdir.'.');

				&make_directory($prjdir.'/'.'addons')
				? ( $log->info('Success create directory \'addons\', by project: \''.$prjdir.'\''))
				: ( $log->error('Error create directory \'addons\' by project: \''.$prjdir.'\'')
				and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! );
			}


			if ( &check_exist_info_scene($prjdir) )
			{
				$log->info('Success check \'info.scene\', project: '.$prjdir.'.');
			}
			else
			{
				$log->warn('Error check \'info.scene\', project: '.$prjdir.'.');

				my $store_duration = $self->connect_plugin('FFMPEG')->set_data(
				{
					'prjdir' => $prjdir,
					'project_files' => $project_files,
#					'mode' => $self->config()->{'mode'}
				})->fetch_duration_project();

				if ( my $status = grep { $_ ~~ $store_duration } @{$self->config()->{'mandatory_files'}} )
				{
					my $e;
					map {
						$store_duration->{$_} > $self->config()->{'min_duration'} ||
						(
						  $e = 1 and $log->warn('Generation of \'info.scene\' disabled or content duration less then or equal '.$self->config()->{'min_duration'}.' sec. File info.scene will not be created. '.'|'.$store_duration->{$_} .' > '. $self->config()->{'min_duration'}.'|')
				##		  and $self->config()->{'mode'} eq 'force' ? 1 : next MAIN;
						)
					} @{$self->config()->{'mandatory_files'}};

					! $e and ( $self->connect_plugin('FFMPEG')->set_data(
					{
						'prjdir' => $prjdir,
						'source' => $self->config()->{'mandatory_files'}->[0],
					})->create_info_scene() ? ( $log->info('By project: ', $prjdir. ', was create \'info.scene\'.') )
					: ( $log->error('Error create \'info.scene\' by project '.$prjdir) and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! ));
				}
				else
				{
					$log->error('Error fetching \'duration\' by required project files, project: '.$prjdir.' files: [ '.&get_line($self->config()->{'mandatory_files'},'eqq').' ]');
					$errors->{$prjdir} = qq|\|$!\| \|$@\||;
					$self->config()->{'mode'} eq 'force' ? next : die $!;
				}
			}


			if ( &check_exist_thumbnails($prjdir) )
			{
				$log->info('Success check \'thumbnails\', project: '.$prjdir.'.');
			}
			else
			{
				$log->warn('Error check \'thumbnails\', project: '.$prjdir.'!');

				my $store_nb_frames = $self->connect_plugin('FFMPEG')->set_value('prjdir' => $prjdir)->fetch_nb_frames();

				if ( my $status = grep { $_ ~~ $store_nb_frames } @{$self->config()->{'mandatory_files'}} )
				{
					my $response = $self->connect_plugin('FFMPEG')->set_data(
					{
						'prjdir' => $prjdir,
						'nb_frames' => $store_nb_frames->{$self->config()->{'mandatory_files'}->[0]},
						'source' => $self->config()->{'mandatory_files'}->[0],
					})->create_thumbnails();

					$response
					? ( $log->info('By project: ', $prjdir. ', was create \'thumbnails\'.') )
					: ( $error->info('Error create \'thumbnails\' by project '.$prjdir.' !') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! );
				}
				else
				{
					$log->error('Error fetching \'nb_frames\' by required project files, project: '.$prjdir.' files: [ '.&get_line($self->config()->{'mandatory_files'},'eqq').' ]');
					$errors->{$prjdir} = qq|\|$!\| \|$@\||;
					$elf->config()->{'mode'} eq 'force' ? next : die $!;
				}
			}

			my $thumbnails = &collect_thumbnails($prjdir)
			|| ( $log->error('By current project: '.$prjdir.', don`t collected \'thumbnails\' !') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! );


			my $main_uuid = &check_uuid_project($prjdir)
			|| ( $log->error('By current project: '.$prjdir.', lack \'uuid\' or \'uuid\' not valid!') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! );

			my ( $uuid_subprojects );
			for my $file ( sort { eqq($b) <=> eqq($a) } keys %$project_files )
			{
				$file =~ /^v\.(nr|lw)\.und\.mp4$/ and last;

				my $uuid = &uuid_generation();
				$uuid_subprojects->{$main_uuid}->{(split(/[.]/,$file))[1]} = $uuid;

				$log->info('Create \''.$prjdir.'/'.$uuid.'.ssm\' directory.');
				mkdir $prjdir.'/'.$uuid.'.ssm'
				|| ( $log->error('Can\'t create \''.$prjdir.'/'.$uuid.'.ssm\' directory: '.$!) and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $!);
				if( -f $prjdir.'/'.$uuid.'.ssm/0AVProjectAlias' )
				{
					$log->warn('File \''.$prjdir.'/'.$uuid.'.ssm/0AVProjectAlias already exist.');
				}
				else
				{
					$log->info('Create \''.$prjdir.'/'.$uuid.'.ssm/0AVProjectAlias\' file.');
					open  AVPROJALIAS, ">", $prjdir.'/'.$uuid.'.ssm/0AVProjectAlias' or
					( $log->error("Can't create '$prjdir/$uuid.ssm/0AVProjectAlias' file: $!") and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );
					print AVPROJALIAS $uuid;
					close AVPROJALIAS;
				}

				&check_uuid_project($prjdir.'/'.$uuid.'.ssm')
				|| ( $log->error('By creating project: '.$prjdir.'/'.$uuid.'.ssm'.', lack \'uuid\' or \'uuid\' not valid!') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );


				my $response = $self->connect_plugin('MP4SPLIT')->set_data(
				{
					'prjdir' => $prjdir,
					'prj_id' => $uuid,
					'drm' => ( $prjdir =~ /tvzavr_d/ ) ? 1 : 0,
					'run_check_key_frame_step' => 1,
					'project_files' => $project_files
				})->create_ism();

				$response
				? ( $log->info('Success create \'ism manifest\', by project: '.$prjdir.'/'.$uuid.'.ssm !') )
				: ( $log->error('Error create \'ism manifest\', by project: '.$prjdir.'/'.$uuid.'.ssm') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );


				$log->info('Creating necessary links for subproject: \''.$prjdir.'/'.$uuid.'.ssm\' to required files for PDL and required source files.');

				my @infilelist;
				map { push @infilelist, $_ } grep { -f $prjdir.'/'.$_ } grep {/^v\.(4k|fhd|hd|hi|nr|lw)\.und\.mp4$/} keys %$project_files;


				$self->env()->{'env'}->{'PWD'} eq $prjdir.'/'.$uuid.'.ssm' or
				( chdir($prjdir.'/'.$uuid.'.ssm') ||
				( $log->error('Can not replace to directory '.$prjdir.'/'.$uuid.'.ssm') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $!) );

				for my $infile ( @infilelist )
				{
					symlink('..'.'/'.$infile, $infile) or
					( $log->error('Can\'t create symlinks for source files: '.$infile.', by subproject: '.$prjdir.'/'.$uuid.'.ssm !')
					and $errors->{$prjdir} = qq|\|$!\| \|$@\||
					and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );

					$prjdir =~ /tvzavr_d/ and next;
					$infile =~ /^v\.(fhd|4k)\.und\.mp4$/ and next;

					my ($v, $prf, $lng, $ext) = split /\./, $infile;
					foreach my $lang (keys%{$store_langs->{$infile}})
					{
						my $fname = "$v.$prf.".$lang.".$ext";
						&encode_utf8_off($fname);
						-e $prjdir.'/'.$fname or ( $log->error('File \''.$prjdir.'/'.$fname.'\' not exist!') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );
						-e $prjdir.'/'.$uuid.'.ssm/'.$fname and $log->warn('Symlink \''.$prjdir.'/'.$uuid.'.ssm/'.$fname.'\' already exist.');

						symlink('..'.'/'.$fname, $fname) or
						($log->error('Can\'t create symlinks for source files: \''.$prjdir.'/'.$fname.' => '.$prjdir.'/'.$uuid.'.ssm/'.$fname.'\' !')
						and $errors->{$prjdir} = qq|\|$!\| \|$@\||
						and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );
					}

					if ( -f $prjdir.'/'.'v.hi.und.mp4' )
					{
						if ( -f $prjdir.'/'.'v.hi.rus.mp4' )
						{
							symlink('..'.'/'.'v.hi.rus.mp4', 'v.mp4');
						}
						elsif ( -f $prjdir.'/'.'v.hi.eng.mp4' )
						{
							symlink('..'.'/'.'v.hi.eng.mp4', 'v.mp4');
						}
						else
						{
							for ( bsd_glob $prjdir.'/'.'v.hi.???.mp4' )
							{
								/v.hi.und.mp4/ and next;
								symlink('../'.(split(/\//,$_))[-1], 'v.mp4');
							}
						}
						-f $prjdir.'/'.$uuid.'.ssm/v.mp4' or
						( $log->error('Can`t create default video file \''.$prjdir.'/'.$uuid.'.ssm/v.mp4\'!') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );
					}
				}
#				chdir( $app_dir ) || ( $log->error('Cant not backward replace to application directory: '.$app_dir.'!') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );


				$log->info('Create \''.$prjdir.'/'.$uuid.'.ssm/addons\' directory.');
				-d $prjdir.'/'.$uuid.'.ssm'.'/'.'addons' or mkdir $prjdir.'/'.$uuid.'.ssm'.'/'.'addons'
				or ( $log->error('Can\'t create \''.$prjdir.'/'.$uuid.'.ssm/addons\' directory: '.$!) and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );


				$log->info('Create \''.$prjdir.'/'.$uuid.'.ssm/addons/srt\' links.');
				for (bsd_glob($prjdir.'/addons/*.srt'))
				{
					/\/([a-z\.]+)$/;
					-f $_ and ! -f $prjdir.'/'.$uuid.'.ssm/'.'addons/'.$1
					and $log->info('Create \''.$prjdir.'/'.$uuid.'.ssm/addons/'.$1.'\' link.')
					and symlink('../../addons/'.$1, $prjdir.'/'.$uuid.'.ssm'.'/'.'addons/'.$1);
				}

				$log->info('Create \''.$prjdir.'/'.$uuid.'.ssm/addons/vtt\' links.');
				for (bsd_glob($prjdir.'/addons/*.vtt'))
				{
					/\/([a-z\.]+)$/;
					-f $_ and ! -f $prjdir.'/'.$uuid.'.ssm/'.'addons/'.$1
					and $log->info('Create \''.$prjdir.'/'.$uuid.'.ssm/addons/'.$1.'\' link.')
					and symlink('../../addons/'.$1, $prjdir.'/'.$uuid.'.ssm'.'/'.'addons/'.$1);
				}


				chdir( $app_dir ) || ( $log->error('Cant not backward replace to application directory: '.$app_dir.'!') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );

				$log->info('Create \''.$prjdir.'/'.$uuid.'.ssm/addons/info.xml\'.');
				open INFOXML, '>', $prjdir.'/'.$uuid.'.ssm'.'/'.'addons/info.xml' ||
				( $log->error('Can\'t open required file \''.$prjdir.'/'.$uuid.'.ssm/addons/info.xml\' '.$!) and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );

				my $info_xml = $self->connect_plugin('FFMPEG')->set_value('prjdir' => $prjdir.'/'.$uuid.'.ssm')->create_info_xml();

				$info_xml and print INFOXML $info_xml or
				( $log->error('Error create \'info.xml\' by subproject: '.$prjdir.'/'.$uuid.'.ssm !') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );
				close INFOXML;


				$log->info('Create \'thumbnails\' links by subproject.');
				for ( keys %$thumbnails )
				{
					-f $prjdir.'/'.'addons'.'/'.$_ and symlink('../..'.'/'.'addons'.'/'.$_, $prjdir.'/'.$uuid.'.ssm'.'/'.'addons'.'/'.$_);
				}


				$log->info('Create \''.$prjdir.'/'.$uuid.'.ssm/addons/info_scene\' link.');
				-f $prjdir.'/'.'addons/info.scene' and symlink('../..'.'/'.'addons/info.scene', $prjdir.'/'.$uuid.'.ssm'.'/'.'addons/info.scene');

				delete($project_files->{$file});


				symlink($prjdir.'/'.$uuid.'.ssm', $self->config()->{'pubdir_l'}.'/'.$self->config()->{'owners_for_unified_streaming'}->{(split(/\//,$prjdir))[2]}.'/stream'.'/'.$uuid.'.ssm')
				|| ( $log->error('Can\'t create required link to \''.$prjdir.'/'.$uuid.'.ssm'.'\' in: \''.$self->config()->{'pubdir_l'}.'/'.$self->config->{'owners_for_unified_streaming'}->{(split(/\//,$prjdir))[2]}.'/stream/'.$uuid.'.ssm\''.$!)
				and $errors->{$prjdir} = qq|\|$!\| \|$@\||
				and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );
				symlink($prjdir.'/'.$uuid.'.ssm/addons', $self->config()->{'pubdir_l'}.'/'.$self->config()->{'owners_for_unified_streaming'}->{(split(/\//,$prjdir))[2]}.'/addons'.'/'.$uuid)
				|| ( $log->error('Can\'t create required link to \''.$prjdir.'/'.$uuid.'.ssm/addons\' in: \''.'/home/unified-streaming/'.$self->config()->{'owners_for_unified_streaming'}->{(split(/\//,$prjdir))[2]}.'/addons/'.$uuid.'\''.$!)
				and $errors->{$prjdir} = qq|\|$!\| \|$@\||
				and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );
			}


			$log->info('Create \'uuid\' and video files conformance list.');
			open WL, '>', $prjdir.'/'.'uuid_subprojects' or
			( $log->error('Can not open \'uuid_subprojects\' file, by project: '.$prjdir.' !') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! );

			my $json = &encode_to_json($uuid_subprojects);

			$json and print WL $json
			or ( $log->error('Error create \'uuid_subprojects\' by subproject: '.$prjdir.'/'.$uuid.'.ssm !') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! );
			close WL;


			( rename $prjdir.'/'.$main_uuid.'.ssm', $prjdir.'/OLD_'.$main_uuid.'.ssm_TYPE' and -d $prjdir.'/OLD_'.$main_uuid.'.ssm_TYPE' )
			|| ( $log->warn('Can`t success rename old project: \''.$prjdir.'/'.$main_uuid.'.ssm\''.$!) and $errors->{$prjdir} = qq|\|$!\| \|$@\|| );


			$prjdir =~ /(tvzavr_d|tvzavr_old_projects|tvzavr|xberry|uzplay|solenkov\.v)/;								## need rewrite to fetch owners from config
			$self->connect_plugin('RSYNC')->set_data(
			{
				'prjdir' => $prjdir,
				'owner' => $1,
				'mode' => 'force'
#				'mode' => 'debug'
			})->sync_main_project() && ( $log->error('Can not perform synchronization all by mainproject: '.$prjdir.' to remote servers: [ '.&get_line($self->config()->{'syncserver'}).' ].')
			and $errors->{$prjdir} = qq|\|$!\| \|$@\||
			and $self->config()->{'mode'} eq 'force' ? next : die $! );


			$self->connect_plugin('DB::MYSQL')->set_sql_safe_updates();


			$self->connect_plugin('DB::MYSQL')->set_data(
			{
				'main_uuid' => $main_uuid,
#				'mode' => 'debug'
			})->delete_from_clip_quality() || ( $log->error('Can not delete string from \'clip_quality\' table by [ \'url\':'.$main_uuid.' ]')
			and $errors->{$prjdir} = qq|\|$!\| \|$@\||
			and $self->config()->{'mode'} eq 'force' ? next : die $! );


			map
			{
				$self->connect_plugin('DB::MYSQL')->set_data(
				{
					'uuid' => $uuid_subprojects->{$main_uuid}->{$_},
					'main_uuid' => $main_uuid,
					'quality' => $self->config()->{'match_qualities_db'}->{$_},
#					'mode' => 'debug'
				})->insert_into_clip_quality()
				|| ( $log->error('Can`t insert to \'clip_quality\' table by parameters: [ \'uuid\'='.$uuid_subprojects->{$main_uuid}->{$_}.', \'main_uuid\'='.$main_uuid.', \'quality\'='.&get_line($self->config()->{'match_qualities_db'}->{$_}).' ]')
				and $errors->{$prjdir} = qq|\|$!\| \|$@\||
				and $self->config()->{'mode'} eq 'force' ? next : die $! );
			} keys %{$uuid_subprojects->{$main_uuid}};


			$self->connect_plugin('DB::MYSQL')->set_data(
			{
				'uuid' => ( map { $uuid_subprojects->{$main_uuid}->{$_} } sort { &eqq($b) <=> &eqq($a) } keys %{$uuid_subprojects->{$main_uuid}} )[0],
				'main_uuid' => $main_uuid,
#				'mode' => 'debug'
			})->update_clip() || ( $log->error('Can not update string from \'clip\' table by [ \'trailer_url\':'. $main_uuid.' ]')
			and $errors->{$prjdir} = qq|\|$!\| \|$@\||
			and $self->config()->{'mode'} eq 'force' ? next : die $! );


			$prjdir =~ /(tvzavr_d|tvzavr_old_projects|tvzavr|xberry|uzplay|solenkov\.v)/;								## need rewrite to fetch owners from config
			map
			{
				$self->connect_plugin('DB::MYSQL')->set_data(
				{
					'uuid' => $uuid_subprojects->{$main_uuid}->{$_},
					'owner'=> $1,
#					'mode' => 'debug'
				})->insert_into_cdn_keys()
				|| ( $log->error('Can`t insert to \'cdn_keys\' table by parameters: [ \'uuid\'='.$uuid_subprojects->{$main_uuid}.', \'owner\'='.$1.' ]')
				and $errors->{$prjdir} = qq|\|$!\| \|$@\||
				and $self->config()->{'mode'} eq 'force' ? next : die $! );
			} keys %{$uuid_subprojects->{$main_uuid}};


			$self->connect_plugin('DB::MYSQL')->set_value(
				'main_uuid' => $main_uuid,
#				'mode' => 'debug'
			)->delete_from_cdn_keys_quality() || ( $log->error('Can not delete string from \'cdn_keys_quality\' table by [ \'main_url\':'.$main_uuid.' ]')
			and $errors->{$prjdir} = qq|\|$!\| \|$@\||
			and $self->config()->{'mode'} eq 'force' ? next : die $! );


			map
			{
				$self->connect_plugin('DB::MYSQL')->set_data(
				{
					'main_uuid' => $main_uuid,
					'uuid' => $uuid_subprojects->{$main_uuid}->{$_},
					'quality' => $self->config()->{'match_qualities_db'}->{$_},
#					'mode' => 'debug'
				})->insert_into_cdn_keys_quality()
				|| ( $log->error('Can`t insert to \'cdn_keys_quality\' table by parameters: [ \'uuid\'='.$uuid_subprojects->{$main_uuid}->{$_}.', \'main_uuid\'='.$main_uuid.', \'quality\'='.&get_line($self->config()->{'match_qualities_db'}->{$_}).' ]')
				and $errors->{$prjdir} = qq|\|$!\| \|$@\||
				and $self->config()->{'mode'} eq 'force' ? next : die $! );
			} keys %{$uuid_subprojects->{$main_uuid}};


			unlink '/home/unified-streaming/'.(split(/\//,$prjdir))[2].'/stream/'.$main_uuid.'.ssm';
			unlink '/home/unified-streaming/'.(split(/\//,$prjdir))[2].'/addons/'.$main_uuid;
		}
		$log->info('End perform \'reassemble_prjoject_to_multiple_subprojects\' route.');
	}

	sub re_assemble_ism_by_project_of_type_multiple
	{
		my ( $self ) = @_;

		$log->info('Begin perform \'re_assemble_ism_by_projects_of_type_multiple\' route.');

		$self->utils(
		[
			'fetch_qualities',
			'get_line',
			'check_uuid_project',
			'eqq',
		]);
		$self->plugin();

		my $env = $self->env();
		my $app_dir = $self->env()->{'env'}->{'PWD'};

		MAIN:
		for my $prjdir ( @{$env->{'argv'}} )
		{
			my $project_files = &fetch_qualities($prjdir);

			map {
				$log->error('Absence required project files, project: '.$prjdir.', files: [ '.&get_line($self->config()->{'mandatory_files'},'eqq').' ]')
				and $errors->{$prjdir} = qq|\|$!\| \|$@\||
				and $self->config()->{'mode'} eq 'force' ? next : die $!
			} grep { not $_ ~~ $project_files } @{$self->config()->{'mandatory_files'}};

#			say 'Mainproject: ', $prjdir;
			for ( bsd_glob($prjdir.'/*.ssm') )
			{

				/([a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12})\.ssm$/ ||
				( $log->error('Finded matching don\`t according type \'uuid\' directory by mainproject: \''.$prjdir.'\' subproject: \''.$_.'\'')
				  and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! );

#				say 'Subproject: ', $_;
				my $uuid = $1;

				my $project_files = &fetch_qualities($_);
				map {
					$log->error('Absence required project files, project: '.$prjdir.', files: [ '.&get_line($self->config()->{'mandatory_files'},'eqq').' ]')
					and $errors->{$prjdir} = qq|\|$!\| \|$@\||
					and $self->config()->{'mode'} eq 'force' ? next : die $!
				} grep { not $_ ~~ $project_files } @{$self->config()->{'mandatory_files'}};


#				say Data::Dumper->Dump([$project_files],['project_files']);
				my $response = $self->connect_plugin('MP4SPLIT')->set_data(
				{
					'prjdir' => $prjdir,
					'prj_id' => $uuid,
					'drm' => ( $prjdir =~ /tvzavr_d/ ) ? 1 : 0,
					'run_check_key_frame_step' => 1,
					'project_files' => $project_files
				})->create_ism();

				chdir( $app_dir ) || ( $log->error('Cant not backward replace to application directory: '.$app_dir.'!') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );


				$log->info('Create \''.$prjdir.'/'.$uuid.'.ssm/addons/info.xml\'.');
				open INFOXML, '>', $prjdir.'/'.$uuid.'.ssm'.'/'.'addons/info.xml' ||
				( $log->error('Can\'t open required file \''.$prjdir.'/'.$uuid.'.ssm/addons/info.xml\' '.$!) and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );

				my $info_xml = $self->connect_plugin('FFMPEG')->set_value('prjdir' => $prjdir.'/'.$uuid.'.ssm')->create_info_xml();

				$info_xml and print INFOXML $info_xml or
				( $log->error('Error create \'info.xml\' by subproject: '.$prjdir.'/'.$uuid.'.ssm !') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );
				close INFOXML;
			}
#			say;
#			say;

			$prjdir =~ /(tvzavr_d|tvzavr_old_projects|tvzavr|xberry|uzplay|solenkov\.v)/;								## need rewrite to fetch owners from config
			$self->connect_plugin('RSYNC')->set_data(
			{
				'prjdir' => $prjdir,
				'owner' => $1,
				'mode' => 'force'
#				'mode' => 'debug'
			})->sync_main_project() && ( $log->error('Can not perform synchronization all by mainproject: '.$prjdir.' to remote servers: [ '.&get_line($self->config()->{'syncserver'}).' ].')
			and $errors->{$prjdir} = qq|\|$!\| \|$@\||
			and $self->config()->{'mode'} eq 'force' ? next : die $! );

			$log->info('End perform \'re_assemble_ism_by_projects_of_type_multiple\' route.');
		}
	}

	sub create_srt2vtt_by_projects_of_type_multiple
	{
		my ( $self ) = @_;


		$log->info('Begin perform \'create_srt2vtt_by_projects_of_type_multiple\' route.');

		$self->utils(
		[
			'fetch_qualities',
			'get_line',
			'eqq',
			'check_exist_addons',
		]);
		$self->plugin();

		my $env = $self->env();
		my $app_dir = $self->env()->{'env'}->{'PWD'};

		MAIN:
		for my $prjdir ( @{$env->{'argv'}} )
		{
			my $project_files = &fetch_qualities($prjdir);

			map {
				$log->error('Absence required project files, project: '.$prjdir.', files: [ '.&get_line($self->config()->{'mandatory_files'},'eqq').' ]')
				and $errors->{$prjdir} = qq|\|$!\| \|$@\||
				and $self->config()->{'mode'} eq 'force' ? next : die $!
			} grep { not $_ ~~ $project_files } @{$self->config()->{'mandatory_files'}};

#			say 'Mainproject: ', $prjdir;

			if ( &check_exist_addons($prjdir) )
			{
				$log->info('Success check \'addons\', project: '.$prjdir.'.');
			}
			else
			{
				$log->warn('Error check \'addons\', project: '.$prjdir.'.');
				$self->config()->{'mode'} eq 'force' ? next : die $!;
			}

			for ( bsd_glob($prjdir.'/*.ssm') )
			{

				/([a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12})\.ssm$/ ||
				( $log->error('Finded matching don\`t according type \'uuid\' directory by mainproject: \''.$prjdir.'\' subproject: \''.$_.'\'')
				  and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next : die $! );


#				say 'Subproject: ', $_;
				my $uuid = $1;

				$self->env()->{'env'}->{'PWD'} eq $prjdir.'/'.$uuid.'.ssm' or
				( chdir($prjdir.'/'.$uuid.'.ssm') ||
				( $log->error('Can not replace to directory '.$prjdir.'/'.$uuid.'.ssm') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $!) );

				if ( &check_exist_addons($prjdir.'/'.$uuid.'.ssm') )
				{
					$log->info('Success check \'addons\', project: '.$prjdir.'/'.$uuid.'.ssm'.'.');
				}
				else
				{
					$log->warn('Error check \'addons\', project: '.$prjdir.'/'.$uuid.'.ssm'.'.');
					$self->config()->{'mode'} eq 'force' ? next : die $!;
				}


				$log->info('Create \''.$prjdir.'/'.$uuid.'.ssm/addons/srt\' links.');
				for (bsd_glob($prjdir.'/addons/*.srt'))
				{
					/\/([a-z\.]+)$/;
					-f $_ and ! -f $prjdir.'/'.$uuid.'.ssm/'.'addons/'.$1
					and $log->info('Create \''.$prjdir.'/'.$uuid.'.ssm/addons/'.$1.'\' link.')
					and symlink('../../addons/'.$1, $prjdir.'/'.$uuid.'.ssm'.'/'.'addons/'.$1);
				}

				$log->info('Create \''.$prjdir.'/'.$uuid.'.ssm/addons/vtt\' links.');
				for (bsd_glob($prjdir.'/addons/*.vtt'))
				{
					/\/([a-z\.]+)$/;
					-f $_ and ! -f $prjdir.'/'.$uuid.'.ssm/'.'addons/'.$1
					and $log->info('Create \''.$prjdir.'/'.$uuid.'.ssm/addons/'.$1.'\' link.')
					and symlink('../../addons/'.$1, $prjdir.'/'.$uuid.'.ssm'.'/'.'addons/'.$1);
				}
			}
			chdir( $app_dir ) || ( $log->error('Cant not backward replace to application directory: '.$app_dir.'!') and $errors->{$prjdir} = qq|\|$!\| \|$@\|| and $self->config()->{'mode'} eq 'force' ? next MAIN : die $! );

			$prjdir =~ /(tvzavr_d|tvzavr_old_projects|tvzavr|xberry|uzplay|solenkov\.v)/;								## need rewrite to fetch owners from config
			$self->connect_plugin('RSYNC')->set_data(
			{
				'prjdir' => $prjdir,
				'owner' => $1,
				'mode' => 'force'
#				'mode' => 'debug'
			})->sync_main_project() && ( $log->error('Can not perform synchronization all by mainproject: '.$prjdir.' to remote servers: [ '.&get_line($self->config()->{'syncserver'}).' ].')
			and $errors->{$prjdir} = qq|\|$!\| \|$@\||
			and $self->config()->{'mode'} eq 'force' ? next : die $! );

		}

		$log->info('End perform \'create_srt2vtt_by_projects_of_type_multiple\' route.');
	}
	1;
