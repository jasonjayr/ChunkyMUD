use strict;

#################################
# Timer routines for ChunkyMUD. #
# by malander 3/6/2001          #
#################################

#################
sub load_timers {
  $timer = new Timer;             # Instantiate a new timer object

  $timer->add_event(D_PLAYER_SAVE(), sub {
    my $rc = t_pfile_queue();
    return $rc;
  });
  
  #######################################################
  # Lag-out timer. Runs every 5 minutes.
  $timer->add_event(D_LAGOUT(), sub {
    my $rc = t_lagout();
    return $rc;
  });
}

##############################
# Playerfile-saving queue code
sub t_pfile_queue {
	
	# so we don't backup the event queue
	# simply schedule a save when the event queue is idle for all
	# current players.
	# since events only fire if there's a reference to them, this 
    # handles all sorts of cases extremely gracefullly. (including eliminating
	# duplicate saves, and stopping the save cb when the client logs off)
	foreach my $client ( $player->getAllClients()) { 
		$client->{save} = AE::idle sub { 
			$player->save_player($client);
			delete $client->{save};
		};
	}
	return D_PLAYER_SAVE();
}

##############
# Lag-out code
sub t_lagout {
  my @all_clients = $player->getAllClients();
  return D_LAGOUT() unless @all_clients;

  foreach my $client (@all_clients) {
    next if (not $player->Name($client));
    my $idletime = time - $player->presence($client);

    if ($idletime >= D_IDLELIMIT()) {
      send_to_player($client, "You have been idle for too long. $nl");
      send_to_player($client, "CONNECTION TERMINATED $nl");
      close_connect($client);
    }
  }

  return D_LAGOUT();
}

1;
