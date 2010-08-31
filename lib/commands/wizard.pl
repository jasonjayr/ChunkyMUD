use strict;

####################################################
# wizard.pl - Contains wizard commands and junk		 #
# -malander 4/10/01  tarael200@aol.com             #
####################################################

####################
# Wizard Commands

#############
sub w_debug {
  my $client = shift;
  my $expr = join(' ', @_);

  send_to_player($client, "Code received: $expr $nl");
  my $result = eval($expr);

  if ($@) {
    send_to_player($client, $@ . $nl);
  } else {
    send_to_player($client, $result);
  }
  
  return 1;
}

###############
sub w_plookup {
  my $client = shift;
  send_to_player($client, join(' ',  keys %plookup));
  return 1;
}

##############
sub w_sdebug {
  my $client = shift;
  send_to_player($client, "Name: " . $player->Name($client) . $nl);
  send_to_player($client, "Level: " . $player->Level($client) . $nl);
  send_to_player($client, "Title: " . $player->Title($client) . $nl);
  send_to_player($client, "Abbrev: " . $player->Abbrev($client) . $nl);
  send_to_player($client, "Autoexit: " . $player->Autoexit($client) . $nl);
  send_to_player($client, "Brief: " . $player->Brief($client) . $nl);
  send_to_player($client, "Curzone: " . $player->Curzone($client) . $nl);
  send_to_player($client, "Curroom: " . $player->Curroom($client) . $nl);
  send_to_player($client, "Last presence: " . $player->presence($client) . $nl);
  return 1;
}

1;

