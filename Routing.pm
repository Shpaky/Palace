#!/usr/bin/perl

	package Routing;

	use 5.12.0;

	use base 'Palace';
	use Data::Dumper;

	sub navigation
	{
		state $self ||= Palace->new();
		$_[0]->{'env'} ||= \%ENV;
		$self->env($_[0]);
		
		say Data::Dumper->Dump([$self->env()],['env']);

		say Data::Dumper->Dump([$self],['self']);
		$self->config('/home/shpaky/system/Work/WE/Palace/conf/conf_app');
		$self->plugin;
		$self->router;
		say Data::Dumper->Dump([$self],['self']);
	#	print "Content-Type: text/html\r\n\r\n";
	#	print "<html> <head>\n";
	#	print "<title>Me managed!</title>";
	#	print "</head>\n";
	#	print "<body>\n";
	#	print "<h3 style=\"color:#1488c6;\">Djany, me managed settings interaction 'nginx' and my application server!<br>This message response my application interaction with my application server by chain:<br>'client' -> 'nginx' -> 'my application server' -> 'my either application which may be enable on my server'</h3><br><h3 style=\"color:red;display:inline-block;padding-left:50%;\">I love you my dear, with love your gentle bear!</h3>\n";
	#	print "<div style=\"color:green;\">pid:$$</div>\n";
	#	print "</body> </html>\n";
	#	print 'Dynamo Moscow!',"\n";

		given($self->env()->{'route'})
		{
			when('route_test') { $self->go_to_route('PersonalCabinet','authorization') }
			when('route_test') { $self->go_to_route('Handler','route_test') }
			when('route_test') { $self->go_to_route('Engine','route_test') }
			when('route_test') { $self->go_to_route('Djany','route_test') }
			when('route_test') { $self->go_to_route('Weekend','route_test') }
			when('route_test') { $self->go_to_route('WE','route_test') }
		}
	}
	1;
