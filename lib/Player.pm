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
			
			if (defined($value)) { P($client)->{$lcfield} = $value; }
			return P($client)->{$lcfield};
		});
	}

	$c->make_immutable();
}



# TODO: i'd rathre this be a proper object
# but this macro lets makes it easier to work with in the interm
sub P { 
	my $client = shift;
	
	confess "Client is not defined!" unless $client;

	$client->Player;

}


sub Dump { return to_json(P($_[1])) }

#######################################################################
########################## PUBLIC #####################################

#############################
# Create a new Player object.
sub new {
  my ($class, $filename) = @_;
  my $self = bless({ } , $class);
  my $hashref = { };
#tie %$hashref, 'Tie::RefHash';
#$self->{PLAYERS} = { };
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
#print "WTF!\n";
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

  if (-e "players/$name.js") {
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
	
  my $file = "players/$name.js";

  if(-e $file) {  
	eval { 
		my @lines = read_file $file; 

		my $hash = from_json(join('',@lines));
	
		# Hopefully this works ;-)
		foreach my $field (keys %$hash) { 

			$self->$field($client, $hash->{$field}) if (defined($hash->{$field}));
		}
	
	};
	if($@) { 
		warn "Cannot read load pfile for $name: (file = $file): $!, $@";
		send_to_player($client, "An error occured with loading your pfile.");
		close_connect($client);
	}
  }
}

#######################
# Save the player data.
sub save_player {
	my ($self, $client) = @_;
	my $name = lc($self->Name($client));        # or return;

	if(!defined($name) || $name eq '') { 
		warn "Attempt to save player with no name! (client = ".(refaddr $client).")";
		return;
	}
	write_file "players/$name.js",
			   to_json(
					   { map { ( $_=>$self->$_($client) ) } @persist_fields },
					   {pretty=>1}
					);

}

###############################################################
# Save a player's structure, then eliminate it from the object.
sub remove {
  my ($self, $client) = @_;
  $self->save_player($client);
  $client->Player({});
  return 1;
}

###########
sub State {
  my ($self, $client, $code) = @_;
  warn +(refaddr $client)." State change = $code\n" if $code;

  if ($code) { P($client)->{state} = $code; }
  return P($client)->{state};
}

###############
sub StateArgs {
  my ($self, $client, $whichone, $value) = @_;

  if ($value and $whichone) {
    # Set the state args
    P($client)->{"state_$whichone"} = $value;
  } else {
    #   If we ever add more state arguments than 2, this should be made smarter
    # getting all the keys of P($client)->, and grepping out the
    # ones that begin with 'state_'.
    if (!$whichone) {
      # They want both
      return (P($client)->{state_1}, P($client)->{state_2});
    } else {
      return P($client)->{"state_$whichone"};
    }
  }
}


##############
sub presence {
  my ($self, $client, $time) = @_;
  if ($time) { P($client)->{ACTIVE_ON} = $time; }
  return P($client)->{ACTIVE_ON};
}


#############################################################
##################### INVENTORY METHODS #####################

#####################################################
# Return a list of objects in the player's inventory.
sub getInventory {
  my ($self, $client) = @_;
  return P($client)->{Inventory};
}

####################
sub manipInventory {
  my ($self, $client, $action, $obj) = @_;

  if ($action eq "ADD") {
    # $obj is a number in this case.
    return (push(@{P($client)->{Inventory}}, $obj) - 1);
  } elsif ($action eq "DELETE") {
    # Find out where in the inventory the object is. $obj is a number in this case.
    for my $i (0 .. @{P($client)->{Inventory}}) {
      if (P($client)->{Inventory}[$i] eq $obj) {
        splice (@{P($client)->{Inventory}}, $i, 1);
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
	
  return map { $_->{sock} } grep { exists($_->{PLAYER}) && $_->{sock} } values %main::clients;

}

################################################################################
# Returns each client in a sequential order. So if you have 3 clients signed on,
# then calling this once returns the first client, calling it twice returns the
# second, etc. Basically for use by playerfile-saving queue code. Be forewarned,
# it gets pretty glitchy with people signing on/off, etc.
sub get_client_ZOMG {
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
#######################################################################

1;
