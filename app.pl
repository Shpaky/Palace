#!/usr/lib/perl

	use 5.010;
	use JSON;
	use Routing;
	use IO::Socket;
	use Data::Dumper;
	use Getopt::Long;

	my ( $route, $projects, $mode );
	my $result = GetOptions
	(
		'route|r:s' => \$route,
		'projects|p:s%{,}' => sub {push(@{$projects->{$_[1]}}, $_[2])},
		'mode|m:s' => \$mode,
		'unix|u:s' => \$unix
	) or die;
	##
	##	route|r = |route|								default|empty|
	##	...........................................................
	##	option 'route' must settled
	##
	##	mode|m = debug|force|combat|multiple						default|combat|
	##	..........................................................
	##	option 'mode' set selectively
	##
	##	unix|u = |path to unix socket|							default|empty|
	##
	##	projects =
	##	{
	##		file 	  => [ project_01, project_02, project_03 ]			default|empty|
	##		.....
	##		list 	  => [ projects_1, projects_2, projects_3 ]			default|empty|
	##		.....
	##		exclude   => [ projects_1, projects_3, projects_3 ]			default|empty|
	##		.......
	##	}
	##	...........................................................
	##	option 'file' and 'list' complement each other
	##	option 'exclude' allow set exсeptions or exception lists
	##
	##	perl app.pl --projects list=list file=file exclude=exceptions exclude=except --mode multiple --unix /tmp/server-unix-socket/socket --route test_multiple_invoke

	my ( $e, %e, $f, $l, $p );
	$projects->{'exclude'} and
	map {
		( -f $_ and $f = $_ ) ||
		( -f $ENV{'PWD'}.'/'.$_ and $f = $ENV{'PWD'}.'/'.$_ ) ||
		( -d $_ and $f = $_ ) and
		-d $f
		? ( push @{$e}, $f )
		: ( open RF, $f and map { push @{$e}, $_ } grep {chomp} <RF> and close RF )
	} @{$projects->{'exclude'}} and @e{@$e} = ( 1 ) x scalar @$e;

	$projects->{'file'} and @$l = map { $_ } grep { -d $_ } @{$projects->{'file'}};

	$projects->{'list'} and
	map {
		( -f $_ and $f = $_ ) || ( -f $ENV{'PWD'}.'/'.$_ and $f = $ENV{'PWD'}.'/'.$_ ) and
		( open RF, $f and map { push @{$l}, $_ } grep {chomp} <RF> and close RF )
	} @{$projects->{'list'}};

	map {
		push @{$p}, $_
	} grep { !$e{$_} } @{$l};

	say Data::Dumper->Dump([$p],['projects']);

	my $error_check;
	{
		$route || ( $error_check = 'Укажите маршрут!', last );

		( $mode eq 'multiple' and ! my $client )
		? map {
			$client = IO::Socket::UNIX->new(Type => SOCK_STREAM(),Peer => $unix) and say {$client} encode_json(
			{
				'argv' => [ $_ ],
				'env'  => \%ENV,
				'route'=> $route
			})
		} @$p
		: &Routing::navigation({'argv' => $p, 'env' => \%ENV, route => $route});

		exit 0;
	}

	die $error_check;
