####################################################
# Player.pm - New OO interface to all the Players. #
# -malander 2/19/2001 tarael200@aol.com            #
####################################################
package Player;
use strict;

#######################################################################
########################## PUBLIC #####################################

#############################
# Create a new Player object.
sub new {
  my ($class, $filename) = @_;
  my $self = bless({ } , $class);
  my $hashref = { };
  tie %$hashref, 'Tie::RefHash';
	$self->{PLAYERS} = { };
  return $self;
}

############################################################
# Add a player's necessary data after he has been validated.
sub init_player {
  my ($self, $client, $name, $gender) = @_;

  $name = $self->Name($client, $self->format_name($name));    # Set the name
  $self->Abbrev($client, 0);                                  # Abbrev defaults to off
  $self->Gender($client, $gender);                            # Set the gender

  # If they exist, load them.
  if ($self->exists_player($client)) {
    $self->load_player($client);
  } else {
    # Apparently they don't exist, so set them up with some crap.
    $self->create_new_player($client);
  }

  $main::plookup{lc($name)} = $client;      # Initialize entry in the plookup table
  &main::c_look($client);                   # Send room desc
  &main::display_prompt($client);           # Send prompt to player

  # Announce their presence.
  &main::send_to_all("The Lord of Code shouts, '$name enters the game!'. $main::nl");
}

#######################################################
# Create a new player file/entry in the %player object.
sub create_new_player {
  my ($self, $client) = @_;

  # Do not set the name here - it's already set.
  $self->State($client, 'COMMAND');
  $self->Abbrev($client, 0);
  $self->Autoexit($client, 1);
  $self->Brief($client, 0);
  $self->Curzone($client, 2);
  $self->Curroom($client, 1);
  $self->Level($client, 1);

  # Save it.
  $self->save_player($client);
}

############################################
# Check to see if a player has a playerfile.
sub exists_player {
  my ($self, $client) = @_;
  my $name = lc($self->Name($client));

  if (-e "players/$name") {
    return 1;
  } else {
    return 0;
  }
}

################
# Load a player.
sub load_player {
  my ($self, $client) = @_;
  my $name = lc($self->Name($client));

  open PLAYER," players/$name" or (send_to_player($client, "An error occured with loading your pfile.") and close_connect($client) and return);
  # Hopefully this works ;-)
  while (<PLAYER>) {
    my ($method, $value) = split '=';
    chomp($value);
    $self->$method($client, $value) if (defined($value));
  }
  close PLAYER;
}

#######################
# Save the player data.
sub save_player {
  my ($self, $client) = @_;
  my $name = lc($self->Name($client));        # or return;

  open PLAYER,"> players/$name" or (&main::logit("Couldn't open player file saving: $!") and return);
  print PLAYER "Name=" . $self->Name($client) . "\n";
  print PLAYER "Gender=" . $self->Gender($client) . "\n";
  print PLAYER "Autoexit=" . $self->Autoexit($client) . "\n";
  print PLAYER "Brief=" . $self->Brief($client) . "\n";
  print PLAYER "Curzone=" . $self->Curzone($client) . "\n";
  print PLAYER "Curroom=" . $self->Curroom($client) . "\n";
  print PLAYER "Level=" . $self->Level($client) . "\n";
  print PLAYER "Title=" . $self->Title($client) . "\n";
  print PLAYER "Abbrev=" . $self->Abbrev($client) . "\n";
  close PLAYER;
}

###############################################################
# Save a player's structure, then eliminate it from the object.
sub remove {
  my ($self, $client) = @_;
  $self->save_player($client);
  delete $self->{PLAYERS}{$client};
  return 1;
}

###########
sub State {
  my ($self, $client, $code) = @_;
  if ($code) { $self->{PLAYERS}{$client}{state} = $code; }
  return $self->{PLAYERS}{$client}{state};
}

###############
sub StateArgs {
  my ($self, $client, $whichone, $value) = @_;

  if ($value and $whichone) {
    # Set the state args
    $self->{PLAYERS}{$client}{"state_$whichone"} = $value;
  } else {
    #   If we ever add more state arguments than 2, this should be made smarter
    # getting all the keys of $self->{PLAYERS}{$client}, and grepping out the
    # ones that begin with 'state_'.
    if (!$whichone) {
      # They want both
      return ($self->{PLAYERS}{$client}{state_1}, $self->{PLAYERS}{$client}{state_2});
    } else {
      return $self->{PLAYERS}{$client}{"state_$whichone"};
    }
  }
}

##########
sub Name {
  my ($self, $client, $name) = @_;
  if ($name) { $self->{PLAYERS}{$client}{name} = $name; }
  return $self->{PLAYERS}{$client}{name};
}

###########
sub Title {
  my ($self, $client, $title) = @_;
  if ($title) { $self->{PLAYERS}{$client}{title} = $title; }
  return $self->{PLAYERS}{$client}{title};
}

#############
sub Curzone {
  my ($self, $client, $curzone) = @_;
  if ($curzone) { $self->{PLAYERS}{$client}{curzone} = $curzone }
  return $self->{PLAYERS}{$client}{curzone};
}

##########
sub Curroom {
  my ($self, $client, $room) = @_;
  if ($room) { $self->{PLAYERS}{$client}{curroom} = $room }
  return $self->{PLAYERS}{$client}{curroom};
}

############
sub Gender {
  my ($self, $client, $gender) = @_;
  if ($gender) { $self->{PLAYERS}{$client}{gender} = $gender; }
  return $self->{PLAYERS}{$client}{gender};
}

###########
sub Level {
  my ($self, $client, $level) = @_;
  if ($level) { $self->{PLAYERS}{$client}{level} = $level; }
  return $self->{PLAYERS}{$client}{level};
}

############
sub Abbrev {
  my ($self, $client, $abbrev) = @_;
  if (defined($abbrev)) { $self->{PLAYERS}{$client}{abbrev} = $abbrev; }
  return $self->{PLAYERS}{$client}{abbrev};
}

##############
sub Autoexit {
  my ($self, $client, $autoexit) = @_;
  if (defined($autoexit)) { $self->{PLAYERS}{$client}{autoexit} = $autoexit; }
  return $self->{PLAYERS}{$client}{autoexit};
}

###########
sub Brief {
  my ($self, $client, $brief) = @_;
  if (defined($brief)) { $self->{PLAYERS}{$client}{brief} = $brief; }
  return $self->{PLAYERS}{$client}{brief};
}

##############
sub presence {
  my ($self, $client, $time) = @_;
  if ($time) { $self->{PLAYERS}{$client}{ACTIVE_ON} = $time; }
  return $self->{PLAYERS}{$client}{ACTIVE_ON};
}

#############
sub LastCmd {
  my ($self, $client, $command) = @_;
  if (defined($command)) { $self->{PLAYERS}{$client}{LastCommand} = $command; }
  return $self->{PLAYERS}{$client}{LastCommand};
}

#################
sub LastCmdHack {
  my ($self, $client, $hack) = @_;
  if (defined($hack)) { $self->{PLAYERS}{$client}{LastCmdHack} = $hack; }
  return $self->{PLAYERS}{$client}{LastCmdHack};
}

#############################################################
##################### INVENTORY METHODS #####################

#####################################################
# Return a list of objects in the player's inventory.
sub getInventory {
  my ($self, $client) = @_;
  return $self->{PLAYERS}{$client}{Inventory};
}

####################
sub manipInventory {
  my ($self, $client, $action, $obj) = @_;

  if ($action eq "ADD") {
    # $obj is a number in this case.
    return (push(@{$self->{PLAYERS}{$client}{Inventory}}, $obj) - 1);
  } elsif ($action eq "DELETE") {
    # Find out where in the inventory the object is. $obj is a number in this case.
    for my $i (0 .. @{$self->{PLAYERS}{$client}{Inventory}}) {
      if ($self->{PLAYERS}{$client}{Inventory}[$i] eq $obj) {
        splice (@{$self->{PLAYERS}{$client}{Inventory}}, $i, 1);
        return 1;
      }
    }
    return 0;                                # Couldn't find what they were looking for - fail.
  } elsif ($action eq "FIND") {              # $obj is an object keyword in this case
     # They're looking up an object in the player's inventory.
     my $objs = $self->getInventory($client);
     return if not $objs;
     return (grep { $main::World->objInfo($_, "Keywords") =~ /\b$obj\b/ } @{$objs});
  } else {
    return 0;                                # Unrecognized action, so fail.
  }
}

################################################################################

###################
sub getAllClients {
  my $self = shift;
  return(keys %{$self->{PLAYERS}});
}

################################################################################
# Returns each client in a sequential order. So if you have 3 clients signed on,
# then calling this once returns the first client, calling it twice returns the
# second, etc. Basically for use by playerfile-saving queue code. Be forewarned,
# it gets pretty glitchy with people signing on/off, etc.
sub get_client {
  my $self = shift;

  my $pl_count = $self->_player_count();
  $self->_player_count($pl_count + 1);

  my @clients = $self->getAllClients();  # Get the number of clients

  # Sanity-checking for possible overflows...
  if ($pl_count > (scalar(@clients) - 1)) {
    $self->_player_count(1);             # Reset the counter to the 2nd one
		return shift(@clients) || "";
  } else {
		return $clients[$pl_count] || ""; 
  }
}

################################
# Return an array containing the
# names of all other players in
# the current room.
sub getPlayersInRoom {
  my ($self, $client) = @_;
  my $curroom = $self->Curroom($client);
  my $curzone = $self->Curzone($client);

  my @array;
  foreach ($self->getAllClients()) {
    next if ($client eq $_);
    push(@array, $self->Name($_)) if ($self->Curroom($_) == $curroom and $self->Curzone($_) == $curzone);
  }

  return @array if (@array);
}

################################
# Return an array containing
# references to all the players
# in the current room.
sub getClientsInRoom {
  my ($self, $client) = @_;
  my $curzone = $self->Curzone($client);
  my $curroom = $self->Curroom($client);

  my @array;
  foreach ($self->getAllClients()) {
    #next if ($client eq $_);
    push(@array, $_) if ($self->Curroom($_) == $curroom and $self->Curzone($_) == $curzone);
  }

  return @array if @array;
}

################################
# Return an array containing the
# names of all other players in
# the current zone.
sub getPlayersInZone {
  my ($self, $client) = @_;
  my $curzone = $self->Curzone($client);

  my @array;
  foreach ($self->getClientsInZone($client)) {
    next if ($client eq $_ or not defined($client));
    push(@array, $self->Name($_)) if ($self->Curzone($_) == $curzone and $self->Name($_));
  }

  return @array if @array;
}

################################
# Return an array containing
# references to all the players
# in the current zone.
sub getClientsInZone {
  my ($self, $client) = @_;
  my $curzone = $self->Curzone($client);

  my @array;
  foreach ($self->getAllClients()) {
    push(@array, $_) if ($self->Curzone($_) == $curzone);
  }

  return @array if @array;
}

################
sub getNameStr {
  my ($self, $client) = @_;
  my $name = $self->Name($client);
  my $title = $self->Title($client);

  my $retstr = $name;
  $retstr .= " $title" if ($title);
  return $retstr;
}

#################
sub format_name {
  my ($self, $name) = @_;
  return ucfirst(lc($name));
}

#######################################################################
########################## PRIVATE ####################################

###################
sub _player_count {
  my ($self, $count) = @_;
  if (defined($count)) {
    $self->{PLAYER_COUNT} = $count;
  }
  return $self->{PLAYER_COUNT};
}

#######################################################################

1;
