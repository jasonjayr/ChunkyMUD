##############################################
# World.pm - New OO interface to the World.  #
# -malander 3/4/2001 tarael200@aol.com       #
##############################################
package World;
use strict;

#######################################################################
########################## PUBLIC #####################################

#############################
# Create a new World object.
sub new {
  my $class = shift;
  my $self = bless({ }, $class);

  # Initialize structure of objects data.
  $self->{Objects} = {
        VNUMS => [],                    # Base array of game objects
      IN_GAME => [],                    # Actual objects that are in play
        REUSE => [],                    # IN_GAME indices that are available for reuse
  };

  # We do not use VNUM 0 or IN_GAME 0
  push(@{$self->{Objects}{VNUMS}}, "");
  push(@{$self->{Objects}{IN_GAME}}, "");

  return $self;
}

#########################################################################
####### Generic World Data

#################
sub DefaultPort {
  my ($self, $port) = @_;
  if ($port) { $self->{DEFPORT} = $port; }
  return $self->{DEFPORT};
}

#############
sub Welcome {
  my ($self, $msg) = @_;
  if ($msg) { $self->{WELCOME} = $msg; }
  return $self->{WELCOME};
}

#############
sub Goodbye {
  my ($self, $msg) = @_;
  if ($msg) { $self->{GOODBYE} = $msg; }
  return $self->{GOODBYE};
}

#############
sub Version {
  my ($self, $version) = @_;
  if ($version) { $self->{VERSION} = $version; }
  return $self->{VERSION};
}

###############
sub StartTime {
  my ($self, $time) = @_;
  if ($time) { $self->{STARTTIME} = $time; }
  return $self->{STARTTIME};
}

##############
sub ListZone {
  my ($self, $lz) = @_;
  if (defined($lz)) { $self->{LISTZONE} = $lz; }
  return $self->{LISTZONE};
}

###########
sub Debug {
  my ($self, $debug) = @_;
  if (defined($debug)) { $self->{DEBUG} = $debug; }
  return $self->{DEBUG};
}

###########
sub xname {
  my ($self, $op, $xname) = @_;
  $xname = lc($xname);
  if ($op eq "ADD" and $xname) {
    push(@{$self->{XNAMES}}, $xname);
    return 1;
  } elsif ($op eq "EXISTS" and $xname) {
    foreach (@{$self->{XNAMES}}) {
      return 1 if ($_ eq $xname);
    }
    return 0;
  }
  return;
}

################################################################
######### Everything Exit-Related

######################################################
# Get the current room's exits in a reasonable format.
# (exit => title as a hash)
sub getFormattedExits {
  my ($self, $curzone, $curroom) = @_;
  my (%exithash, $fc);

  foreach ('north', 'south', 'east', 'west', 'up', 'down') {
    $fc = substr($_, 0, 1);

    my $link = $self->{'Zone_'.$curzone}{Rooms}{exits}{$fc}[$curroom];
    # Is the link hard or sort?
    if (defined($link) && $link !~ /:/ and $link > 0) {
      # Soft link - just snatch up the title.
      $exithash{$_} = $self->{'Zone_'.$curzone}{Rooms}{title}[$link];
    } elsif(defined $link) {
      my ($zonenum, $roomnum) = split ':', $link;
      if ($roomnum > 0) {
        $exithash{$_} = $self->{'Zone_'.$zonenum}{Rooms}{title}[$roomnum];
      }
    }
  }

  # If there are no available exits, return none.
  if (not scalar(keys(%exithash))) {
    return { none => undef };
  } else {
    return \%exithash;
  }
}

use Data::Dumper;

sub WalkRooms { 
	my ($self) = @_;

	my %seen;

	my @stack;
	push @stack, '1:1';
	
	my @exits = split //, 'nsweup';
	my ($zone, $room);	
	my $r = sub { 
		my ($roomkey,$key) = @_;
		if(!$key) { $key = $roomkey; $roomkey = $room; }

		$self->{'Zone_'.$zone}{Rooms}{$key}[$roomkey];
	};
	my $re = sub { 
		my ($roomkey,$dir) = @_;
		if(!$dir) { $dir = $roomkey; $roomkey = $room; }

		$self->{'Zone_'.$zone}{Rooms}{exits}{$dir}[$roomkey];
	};

	print qq|digraph ChunkyMUD { \n |;

	while(@stack) { 
		($zone,$room) = split /:/,pop @stack;
		next if $seen{"$zone:$room"};
		$seen{"$zone:$room"} = 1;

		my $title = $r->('title');
		my %exits;

		foreach my $dir (@exits) { 
			my $link = $re->($dir);
			if(defined($link)) { 
			
				if($link !~ m/:/) { 
					$link = "$zone:$link";
				}
				$exits{$dir} = $link;
				push @stack, $link;;
			}
			
		}
		printf qq|  room_z%ir%i [label="%s"];\n|, $zone, $room, $title;

		printf qq|  room_z%ir%i -> room_z%ir%i [label="%s"];\n|,
			   $zone, $room,
			   split(/:/, $exits{$_}),
			   $_ foreach keys %exits;

		#print Dumper({title=>$title, ex=>\%exits});
	}

	print qq| }\n |;

	exit;
}

#######################################
# Display all the exits in a reasonable
# and tidy manner. Needs a better place
# to go.
sub display_exits {
  my ($self, $client, $exithash) = @_;

  if (exists($exithash->{none})) {
    &main::send_to_player($client, "${main::nl}Exits: None ${main::nl}");
    return;
  }

  &main::send_to_player($client, "${main::nl} You see the following exits: ${main::nl}");
  foreach (('north', 'south', 'east', 'west', 'up', 'down')) {
    &main::send_to_player($client, "  $_ - $exithash->{$_} ${main::nl}") if $exithash->{$_};
  }
}

#############
sub getExit {
  my ($self, $curzone, $curroom, $exit) = @_;
  my $link = $self->{'Zone_'.$curzone}{Rooms}{exits}{$exit}[$curroom];
  # Is the link hard or sort?
  if ($link and $link !~ /:/) {
    return abs($link);
  } else {
    my ($zonenum, $roomnum) = $link =~ m/(\d+):(\d+)/;
    return ($zonenum, abs($roomnum));
  }
}

###########################################
# pass it a letter and get a full exit name
sub expandExit {
  my ($self, $exit_letter) = @_;

  # This should probably be a hash.
  $exit_letter eq 'n' and return 'north';
  $exit_letter eq 's' and return 'south';
  $exit_letter eq 'e' and return 'east';
  $exit_letter eq 'w' and return 'west';
  $exit_letter eq 'u' and return 'up';
  $exit_letter eq 'd' and return 'down';

  return $exit_letter;
}

##################################################################
######### Leftovers (Still important stuff)

################
# Get room info.
sub getRoomInfo {
  my ($self, $curzone, $curroom, $whichone) = @_;
  my ($roomtitle, $roomdesc);

  if (!$whichone) {
    $roomtitle = $self->{'Zone_'.$curzone}{Rooms}{title}[$curroom];
    $roomdesc = $self->{'Zone_'.$curzone}{Rooms}{desc}[$curroom];
  } elsif ($whichone == 1) {
    $roomtitle = $self->{'Zone_'.$curzone}{Rooms}{title}[$curroom];
  } elsif ($whichone == 2) {
    $roomdesc = $self->{'Zone_'.$curzone}{Rooms}{desc}[$curroom];
  }

  return ($roomtitle, $roomdesc);
}

################
# Load the world
sub load_world {
  my $self = shift;
  my @zonedirs = glob("world/*");

  my $Z_ROOMS = "/rooms.pl";
  my $Z_OBJS = "/objs.pl";

  # Load in all the zone files.
  foreach (@zonedirs) {
    # Load the rooms file
    if (-e $_.$Z_ROOMS) {
      require $_.$Z_ROOMS;
    } else {
      &main::logit("$_ does not have a rooms file!");
    }

    # Load the objects file
    if (-e $_.$Z_OBJS) {
      require $_.$Z_OBJS;
    } else {
      &main::logit("$_ does not have an objects file!");
    }
  }

  # Cleanup all the data
  $self->cleanup_rooms();
  $self->generate_listzone_data();
}

###################################################################
##### New code as of 3/23/2001 for managing objects within the game

#######################################
# Pushes an object onto the vnums array
sub objCreate {
  my ($self, $hashref) = @_;
  return if (not keys(%$hashref));
  my $psb_id = pop @{$self->{Objects}{REUSE}};

  if ($psb_id) {
    $self->{Objects}{VNUMS}[$psb_id] = $hashref;
    return $psb_id;
  } else {
    return (push(@{$self->{Objects}{VNUMS}}, $hashref) - 1);
  }
}

#########################################
# Set and get information on in-game objs
sub objInfo {
  my ($self, $objnum, $key, $value, $debug) = @_;
  return if not $objnum;

  if (!defined($objnum) and !$key and !$value) {
    # Return the number of objs that are in-game
    return(scalar @{$self->{Objects}{IN_GAME}});
  }
  if ($objnum and (!$key and !$value)) {
    # Return a hash reference
    return($self->{Objects}{IN_GAME}[$objnum]) if (defined($self->{Objects}{IN_GAME}[$objnum]));
  }

  if ($value) { $self->{Objects}{IN_GAME}[$objnum]{$key} = $value }
  # Return a specific value for a key
  return($self->{Objects}{IN_GAME}[$objnum]{$key});
}

##################################################################
# Clones an object from the vnums array onto the in-game obj array
sub objClone {
  my ($self, $objnum) = @_;
  return if (not $objnum);
  my $hr = &main::copyHash($self->{Objects}{VNUMS}[$objnum]);
  # Maintain a copy of the VNUM it was cloned from
  $hr->{OrigNum} = $objnum;
  return (push(@{$self->{Objects}{IN_GAME}}, $hr) - 1);
}

#############################################
# Destroys an object on the in-game obj array
sub objDestroy {
  my ($self, $objnum) = @_;
  $self->{Objects}{IN_GAME}[$objnum] = undef;
  push(@{$self->{Objects}{REUSE}}, $objnum);
  return 1;
}

###########################################
# Lookup object numbers based on it's name.
sub objLookup {
  my ($self, $loctype, $loc1, $loc2, $keyword) = @_;
  $keyword = lc($keyword);

  # They're looking up an object in a specific zone/room.
  if ($loctype == &main::L_ROOM()) {
    my @objs = $self->getObjectsInRoom($loc1, $loc2);
    return (grep { $self->objInfo($_, "Keywords") =~ /\b$keyword\b/ } @objs);
  }
}

###################################################
# Check to see if a particular object effect exists
sub objEffects {
	my ($self, $objnum, $effect) = @_;
	return 1 if (index($self->objInfo($objnum, "Effects"), $effect) >= 0);
	return 0;
}

#####################
sub parseObjectName {
	my ($self, $string) = @_;
	$string = lc $string;
	$string =~ /^(\d{0,})\.?(.+?)$/;

	my $prefix = 0;	
	if ($1 and $2) {
		$prefix = $1;
	  $string = $2;
	} elsif (not $1 and $2) {
		$string = $2;
		$prefix = 1;
	} else {
		return;
	}	
	return ($prefix, $string);
}

################################
# Get all the objects in a room.
sub getObjectsInRoom {
  my ($self, $curzone, $curroom) = @_;
  my @results;

  for my $i (1 .. (scalar(@{$self->{Objects}{IN_GAME}}) - 1) ) {
    if ($self->objInfo($i, "CurLocType") == &main::L_ROOM() and $self->objInfo($i, "CurLoc1") == $curzone and $self->objInfo($i, "CurLoc2") == $curroom) {
      push(@results, $i);
    }
  }

  return(@results);
}

#####################################################################################
#### All these methods are used by zone data files ##################################
#####################################################################################

##########################
# Create a new zone entry.
sub z_newZone {
  my ($self, $zonenum, $zonetitle, $zoneauthors) = @_;

  # Fill out the basic structure of that zone.
  $self->{'Zone_'.$zonenum} = {
      Title => $zonetitle,
    Authors => $zoneauthors,
      Rooms => {
        title => [ ],
        desc  => [ ],
        exits => {
              n => [],
              s => [],
              e => [],
              w => [],
              u => [],
              d => []
        }
      }
  };
}

##################################################################################
############ Room Abstraction Layer ##############################################

####################
# Set a room title.
sub z_setRoomTitle {
  my ($self, $zonenum, $roomnum, $title) = @_;
  if (not $zonenum || not $roomnum || $title) {
      my ($file, $line) = (caller(1))[1,2];
      &main::logit("z_setRoomTitle(): Field missing - called from file ${file}, line $line");
  }
  $self->{'Zone_'.$zonenum}{Rooms}{title}[$roomnum] = $title;
}

###################
# Set a room desc.
sub z_setRoomDesc {
  my ($self, $zonenum, $roomnum, $desc) = @_;
  if (not $zonenum || not $roomnum || $desc) {
      my ($file, $line) = (caller(1))[1,2];
      &main::logit("z_setRoomTitle(): Field missing - called from file ${file}, line $line");
  }
  $self->{'Zone_'.$zonenum}{Rooms}{desc}[$roomnum] = $desc;
}

######################
# Setup the room exits
sub z_setExits {
  my ($self, $zonenum, $roomnum, $exit_ltr, $link) = @_;
  if (not $zonenum || not $roomnum || not $exit_ltr || not $link) {
      my ($file, $line) = (caller(1))[1,2];
      &main::logit("z_setRoomTitle(): Field missing - called from file ${file}, line $line");
  }
  $self->{'Zone_'.$zonenum}{Rooms}{exits}{$exit_ltr}[$roomnum] = $link;
}

##################################################################################
############ Object Abstraction Layer ############################################

######################
# Create a new object.
sub z_newObject {
  my ($self, $hr) = @_;

  # Sanity-checking to make sure all the necessary values are present.
  foreach (('Name', 'ShortDesc', 'LongDesc', 'Keywords', 'ItemType', 'OrigLocType', 'OrigLoc1', 'OrigLoc2', 'Effects', 'Weight', 'Value')) {
    if (not $hr->{$_}) {
      # Find out where we were called from.
      my ($file, $line) = (caller(1))[1,2];
      &main::logit("Object Creation: $_ field missing in hashref passed to z_newObject(), called from file ${file}, line $line");
    }
  }

  # Here we need to cleanup the object data.
  $hr->{ShortDesc} = &main::convert_to_inet($hr->{ShortDesc});
  $hr->{LongDesc} = &main::convert_to_inet($hr->{LongDesc});
  $hr->{Keywords} = lc($hr->{Keywords});       # Lowercase the object keywords

  # Duplicate the OrigLocType/OrigLoc1/OrigLoc2 values into CurLocType, CurLoc1, CurLoc2
  foreach (('LocType', 'Loc1', 'Loc2')) {
    $hr->{'Cur'.$_} = $hr->{'Orig'.$_};
  }

  # Actually create the object.
  my $objnum = $self->objCreate($hr);
  $self->objClone($objnum);
}

#######################################################################
########################## PRIVATE ####################################

##############################################
# Part of the process of initializing rooms.
# We need to add $nl's to room titles, and
# change the newlines in room descriptions.
sub cleanup_rooms {
  my $self = shift;
  my @zonenums = $self->getZoneNums();

  foreach (@zonenums) {
    my $count = scalar(@{$self->{$_}{Rooms}{title}});

    # We do not use room 0 :-)
    for my $x (1 .. $count - 1) {
      $self->{$_}{Rooms}{title}[$x] = &main::convert_to_inet($self->{$_}{Rooms}{title}[$x]);
      $self->{$_}{Rooms}{desc}[$x] =~ s/\n/\015\012/;
      $self->{$_}{Rooms}{desc}[$x] = &main::convert_to_inet($self->{$_}{Rooms}{desc}[$x]);
    }
  }
}

############################
sub generate_listzone_data {
  my $self = shift;
  my @zonenums = $self->getZoneNums();

  # Maybe this should be redone using formats?
  my @lz_array = ();
  push (@lz_array, "List of ChunkyMUD Zones");
  push (@lz_array, "-----------------------");
  push (@lz_array, "Zone # - Title/Authors");

  my $i = 0;
  foreach (@zonenums) {
    my ($zonenum) = $_ =~ m/^Zone_(\d+)/;
    my $authorstring = $self->{$_}{Title} . " (" . $self->{$_}{Authors} . ")";
    push (@lz_array, "$zonenum - $authorstring");
  }

  my $lz_text = join("$main::nl", @lz_array);
  $self->ListZone($lz_text);
}

#################
sub getZoneNums {
  my $self = shift;
  return (grep { m/^Zone_\d+/ } keys %$self);
}
#######################################################################

1;
