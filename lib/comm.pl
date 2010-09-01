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
  $clients{refaddr $client}->{h}->push_write($message) if defined($message);
#$outbuffer{$client} .= $message if (defined $message);
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
    next if ($_ eq $clientto or $_ eq $clientfrom);
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
  return send_to_player($client,$message);

#  $clients{refaddr $client}->push_write($message) 
#  my $rv = $client->send($message, 0);
#
#  unless (defined $rv) {
#    return;
#  }
#
#  if ($rv == length $message || $! == POSIX::EWOULDBLOCK) {
#    # This is here for no particular reason ;-)
#  } else {
#    # Couldn't write all the data, so shutdown and move on.
#    close_connect($client);
#  }
}

################################################
# Close a specific connection. Pass it a client.
sub close_connect {
  my $client = shift;
  my $name = lc($player->Name($client));

  #$select->remove($client);
  $player->remove($client);
  delete $clients{refaddr $client}; 


  if (exists $plookup{$name}) { delete $plookup{$name} };
  return 1;
}

#######################################################
# nonblock($socket) puts a socket into nonblocking mode
sub nonblock {
  my $socket = shift;
  $socket->blocking(1);
	warn '[DEPRICATED] call to chunkymud nonblock()';

  #my $flags = fcntl($socket, F_GETFL, 0) or die "Can't get flags for socket: $!\n";
  #  fcntl($socket, F_SETFL, $flags | O_NONBLOCK) or die "Can't make socket nonblocking: $!\n";
}

=begin
###############################
# Turn client echoing on or off
sub client_echo {
  my $client = shift;
  if (shift == 1) {
    # ENABLE ECHO
    # (IAC WON'T ECHO)
    send_to_player($client,"\377\374\001");
    # (IAC DO ECHO)
    send_to_player($client,"\377\375\001");
    $client_echo{$client} = 1;
  } else {
    # DISABLE ECHO
    # (IAC WILL ECHO)
    send_to_player($client,"\377\373\001");
    # (IAC DONT ECHO)
    send_to_player($client,"\377\376\001");
    $client_echo{$client} = -1;
  }
}



#################################################
# Filter special control codes from telnet client
sub HandleIAC {
  my ($client, $t_buffer, $t_data) = @_;
  warn "-A t_buffer=$t_buffer";
  warn "-A t_data=$t_data";
  warn "client_echo = " . $client_echo{$client};
  
  if ($t_buffer eq $t_data) { warn "returning???"; send_to_player($client, $t_data); return $t_data; }

  # Filter out any IAC DO or DON'T ECHO client replies
  $t_buffer =~ s/([^\377])?\377[\375\376]\001/$1/g;

  warn "-B t_buffer=$t_buffer";
  warn "-B t_data=$t_data";


  # Check for IAC WON'T ECHO client reply
  # This will enable echo by server for telnet clients that have no local echo
  if ($t_buffer =~ s/([^\377])?\377\373\001/$1/g) {
    # Make sure isn't -1 (forced echo off)
    if ($client_echo{$client} != -1) {
      $client_echo{$client} = -1;
    }
  }

  warn "-C t_buffer=$t_buffer";
  warn "-C t_data=$t_data";

  # Check for IAC WILL ECHO client reply
  if ($t_buffer =~ s/([^\377])?\377\374\001/$1/g) {
    # Make sure isn't -1 (forced echo off)
    if ($client_echo{$client} != -1) {
      $client_echo{$client} = 0;
    }
  }

  # HANDLE BACKSPACE
  while (1) {
    # Continue until no more nonbackspace followed by backspace
    if ($t_buffer =~ s/[^\010](\010)//g || $t_buffer =~ s/[^\177](\177)//g) {
      send_to_player($client,"$1 $1");
    } else {  
      last;
    }
  }

  warn "-D t_buffer=$t_buffer";
  warn "-D t_data=$t_data";


  # GET RID OF ANY BACKSPACES NOT CAUGHT (IE ON A BLANK LINE)
  $t_buffer =~ s/\010|\177//g;

  # Echo to client if echo has been enabled
  if ($client_echo{$client} == -1) {
    warn "t_data = $t_data before";
    $t_data =~ s/[^\010](\010)//g;
    $t_data =~ s/[^\177](\177)//g;
    $t_data =~ s/\010|\177//g;
    warn "t_data = $t_data after";
    send_to_player($client, $t_data);
    #send_to_player($client, $t_buffer);
  }

  return $t_buffer;
}
=cut

1;
