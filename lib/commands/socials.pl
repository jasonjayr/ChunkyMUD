use strict;

##################################################
# socials.pl - Contains all subroutines that are #
# used in socials.                               #
# -malander 3/3/2001  tarael200@aol.com          #
##################################################

############
sub s_rofl {
  my ($client, $target) = @_;

  if (not $target) {
    send_to_player($client, "You roll on the floor laughing at nothing at all! $nl");
    send_to_room_except($client, undef, $player->Name($client) . " rolls on the floor laughing! $nl");
  } else {
    # Change it from a name to a client object.
    $target = $plookup{lc($target)};

    if ($player->Curzone($client) != $player->Curzone($target) or $player->Curroom($client) != $player->Curroom($target)) {
      return "They are not here!";
    }

    send_to_player($client, "You roll on the floor laughing at " . $player->Name($target) . "! $nl");
    send_to_room_except($client, $target, $player->Name($client)." rolls on the floor laughing at " . $player->Name($target) .  "! $nl");
    send_to_player($target, $player->Name($client)." rolls on the floor laughing at you! $nl");
  }

  return 1;
}

############
sub s_amoo {
  my ($client, $target) = @_;

  if (not $target) {
    send_to_player($client, "You let out an angry MOOOOOOOOO!");
    send_to_room_except($client, undef, $player->Name($client) . " snarls and goes MOOOOOOOO! $nl");
  } else {
    # Change it from a name to a client object.
    $target = $plookup{$target};

    if ($player->Curzone($client) != $player->Curzone($target) or $player->Curroom($client) != $player->Curroom($target)) {
      return "You must be crazy - not only are you mooing but you're seeing people that aren't there!";
    }

    send_to_player($client, "You hiss and moo angrily at " . $player->Name($target) . "! $nl");
    send_to_room_except($client, $target, $player->Name($client)." hisses and moos angrily at " . $player->Name($target) .  "! $nl");
    send_to_player($target, $player->Name($client)." moos angrily at you! $nl");
  }

  return 1;
}

1;
