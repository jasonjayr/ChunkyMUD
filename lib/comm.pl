use strict;

#########################################
# Communication routines for ChunkyMUD. #
# This description updated on 2/16/2001 #
# by malander - tarael200@aol.com       #
#########################################

#############################
# Send a message to a player.
sub send_to_player {
  my ($client, $message) = @_;
  $client->push_write($message) if defined($message);
}

########################################
# Send a message to everyone in the zone
sub send_to_zone {
  my ($client, $message) = @_;
  my @sendto = $player->getClientsInZone($client);

  foreach (@sendto) {
    send_to_player($_, $message);
  }
}

########################################
# Send a message to everyone in a zone
# excluding the 1-2 clients that are 
# passed.
sub send_to_zone_except {
  my ($clientfrom, $message) = @_;
  my @sendto = $player->getClientsInZone($clientfrom);      # Exclude from one

  # Now we want to exclude from the other..
  foreach (@sendto) {
    next if ($_ eq $clientfrom);
    send_to_player($_, $message);
  }
}

##################
# Send to the room
sub send_to_room {
  my ($client, $message) = @_;
  my @sendto = $player->getClientsInRoom($client);

  foreach (@sendto) {
    send_to_player($_, $message);
  }
}

#####################################
# Send to everyone in the room except
# for TWO people. 
sub send_to_room_except {
  my ($clientfrom, $clientto, $message) = @_;
  my @sendto = $player->getClientsInRoom($clientfrom);

  # Now we want to exclude from the other..
  foreach (@sendto) {
    next if ($_ eq $clientto||'' or $_ eq $clientfrom||'');
    send_to_player($_, $message);
  }
}

#######################################
# Send a message to everyone signed on.
sub send_to_all {
  my $message = shift;

  foreach ($player->getAllClients()) {
    next if ($player->State($_) ne 'COMMAND');
    send_to_player($_, "$message $nl");
  }
}

##################################################
# Send a message INSTANTANEOUSLY to a player w/out
# going through all that buffering stuff in the
# main loop.
sub send_direct {
  my ($client, $message) = @_;
  warn "[DEPRICATED] call to send_direct\n";
  return send_to_player($client,$message);
}

################################################
# Close a specific connection. Pass it a client.
sub close_connect {
  my $client = shift;
  my $name = lc($player->Name($client));

  #$select->remove($client);
  $player->remove($client);
  $client->handle->push_shutdown;

  delete $clients{refaddr $client}; 


  if (exists $plookup{$name}) { delete $plookup{$name} };
  return 1;
}

1;
