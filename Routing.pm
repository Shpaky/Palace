#!/usr/bin/perl

	package Routing;

	use 5.10.0;

	use base 'Palace';
	use Data::Dumper;

	sub navigation
	{
		state $self ||= Palace->new();

		$_[0]->{'env'} ||= \%ENV;
		$self->env($_[0]);

		open  WD, '>', '/tmp/REQUEST';
		say   WD Data::Dumper->Dump([$self->env()],['env']);
		close WD;
		
		$self->config('/home/shpaky/system/Work/WE/Palace/conf/conf_app');
		$self->plugin;
		$self->router;

		given($self->env()->{'route'})
		{
			when('route_test') { $self->go_to_route('Handler','route_test') }
			when('route_test') { $self->go_to_route('Engine','route_test') }
			when('route_test') { $self->go_to_route('Djany','route_test') }
			when('route_test') { $self->go_to_route('Weekend','route_test') }
			when('route_test') { $self->go_to_route('WE','route_test') }
		}

		given($self->connect_plugin('HTTP::Server')->request_method())
		{
			when('GET')
			{
				given($self->connect_plugin('HTTP::Server')->url())
				{
					when('/start')
					{
						$self->go_to_route('PersonalCabinet','start_page')
					}
					when('/info')
					{
						$self->go_to_route('PersonalCabinet','get_info')
					}
				}
			}
			when('POST')
			{
				given($self->connect_plugin('HTTP::Server')->request_url())
				{
					when('/auth')
					{
						$self->go_to_route('PersonalCabinet','authorization')
					}
					when('/reg')
					{
						$self->go_to_route('PersonalCabinet','registration')
					}
					when('/info')
					{
						$self->go_to_route('PersonalCabinet','set_info')
					}
				}
			}
		}
	}
	1;
