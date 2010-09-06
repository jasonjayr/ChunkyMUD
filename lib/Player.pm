####################################################
# Player.pm - New OO interface to all the Players. #
# -malander 2/19/2001 tarael200@aol.com            #
####################################################
package Player;
use File::Slurp qw(read_file write_file);
use Scalar::Util qw(refaddr blessed);
use JSON;
use Carp;
use strict;
use ChunkyMUD::Player;

our @fields;
our @persist_fields;

@persist_fields = qw(Name Gender Curzone Curroom Level Abbrev Autoexit Title Brief);
@fields = (@persist_fields,qw(LastCmd LastCmdHack));

{ 

	# Generate Accessors for all our functions
	use Class::MOP;
	my $c = Class::MOP::Class->initialize(__PACKAGE__);
	foreach my $field (@fields) { 
		my $lcfield = lc($field);
		$c->add_method($field=>sub { 
			my ($self, $client, $value) = @_;
			
			if(@_ == 2) { 
				$client->Player->$field();
			} else { 
				$client->Player->$field($value);
			}

			#return P($client)->{$lcfield};
		});
	}

	$c->make_immutable();
}

#######################################################################
########################## PUBLIC #####################################


############################################################
# Add a player's necessary data after he has been validated.
sub init_player {
  my ($self, $client, $name, $gender) = @_;
 

  my $newplayer = ChunkyMUD::Player->new($name);
  $client->Player($newplayer);
 
  $newplayer->Load();

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
  $client->State('COMMAND');

  # Save it.
  $client->Player->Save();
  $self->save_player($client);
}

###############################################################
# Save a player's structure, then eliminate it from the object.
sub remove {
  my ($self, $client) = @_;
  $client->Player->Save();
  $client->logout;
  return 1;
}

###########
sub State {
  my ($self, $client, $code) = @_;
  $client->log(debug=>"State change $code") if $code;

  if ($code) { $client->State($code); }
  return $client->State;
}

###############
sub StateArgs {
  my ($self, $client, $whichone, $value) = @_;

  if ($value and $whichone) {
    # Set the state args
    $client->{"state_$whichone"} = $value;
  } else {
    #   If we ever add more state arguments than 2, this should be made smarter
    # getting all the keys of P($client)->, and grepping out the
    # ones that begin with 'state_'.
    if (!$whichone) {
      # They want both
      return ($client->{state_1}, $client->{state_2});
    } else {
      return $client->{"state_$whichone"};
    }
  }
}


##############
sub presence {
  my ($self, $client, $time) = @_;
  if ($time) { $client->{ACTIVE_ON} = $time; }
  return $client->{ACTIVE_ON};
}


#############################################################
##################### INVENTORY METHODS #####################

#####################################################
# Return a list of objects in the player's inventory.
sub getInventory {
  my ($self, $client) = @_;
  return $client->Player->{Inventory};
}

####################
sub manipInventory {
  my ($self, $client, $action, $obj) = @_;

  if ($action eq "ADD") {
    # $obj is a number in this case.
    return (push(@{$client->Player->{Inventory}}, $obj) - 1);
  } elsif ($action eq "DELETE") {
    # Find out where in the inventory the object is. $obj is a number in this case.
    for my $i (0 .. @{$client->Player->{Inventory}}) {
      if ($client->Player->{Inventory}[$i] eq $obj) {
        splice (@{$client->Player->{Inventory}}, $i, 1);
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
	
  return grep { $_->has_player } values %main::clients;
}


################################
# Return an array containing the
# names of all other players in
# the current room.
sub getPlayersInRoom {
  my ($self, $client) = @_;
  
  return map { $_->Player->Name } $self->getClientsInRoom($client);
}

################################
# Return an array containing
# references to all the players
# in the current room.
sub getClientsInRoom {
  my ($self, $client) = @_;
  my $curroom = $client->Player->Curroom;
  my $curzone = $client->Player->Curzone;

  my @array;
  foreach ($self->getAllClients()) {
    next if ($client eq $_);
    push(@array, $_) if ($_->Player->Curroom == $curroom and $_->Player->Curzone == $curzone);
  }

  return @array if @array;
  return;
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
  my $name = $client->Player->Name;
  my $title = $client->Player->Title;

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
#######################################################################

1;
