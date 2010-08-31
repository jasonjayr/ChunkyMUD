use strict;

#################################
# Timer routines for ChunkyMUD. #
# by malander 3/6/2001          #
#################################

#################
sub load_timers {
  $timer = new Timer;             # Instantiate a new timer object

  ######################################################
  # Playerfile-saving queue timer. Runs every minute.
  $player->_player_count(0);
  
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
  my $client = $player->get_client() || return D_PLAYER_SAVE();       # Pick a client off the tree!
  $player->save_player($client);    													        # Save the client.
  return D_PLAYER_SAVE();
}

##############
# Lag-out code
sub t_lagout {
  my @all_clients = $player->getAllClients() || return D_LAGOUT();	# Return if no clients.

  foreach (@all_clients) {
    next if (not $player->Name($_));
    my $idletime = time - $player->presence($_);

    if ($idletime >= D_IDLELIMIT()) {
      send_direct($_, "You have been idle for too long. $nl");
      send_direct($_, "CONNECTION TERMINATED $nl");
      close_connect($_);
    }
  }

  return D_LAGOUT();
}

1;
