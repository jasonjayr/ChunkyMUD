use strict;

####################################################
# Commands.pl - Contains all subroutines that      #
# process user-commands. i.e., help(), say(), etc. #
# -malander 12/27/00  tarael200@aol.com            #
####################################################

#################################################
# Fill the @commands array using neato algorithms
sub load_commands {

    #####################################################################
    # These are, for the most part, arranged in alphabetical order.
    # However, in other parts I've set them up so that they get handled
    # first with the abbrev code.. This allows sort of a command-ordering
    # system so that the most popular commands get picked first.

    @commands = (
          2,                          # Number of fields per record
          'abbrev', undef, undef,
        'autoexit', undef, undef,
		  			'amoo', undef, C_SOCIAL(),
           'brief', undef, undef,
            'down', undef, undef,
            'drop', undef, undef,
           'debug', undef, C_WIZARD(),
            'east', undef, undef,
           'emote', undef, undef,
           'exits', undef, undef,
             'get', undef, undef,
        'gameinfo', undef, undef,
            'give', undef, undef,
            'help', undef, undef,
       'inventory', undef, undef,
            'look', undef, undef,
        'listzone', undef, undef,
           'north', undef, undef,
          'passwd', undef, undef,
         'plookup', undef, C_WIZARD(),			
		   			'quit', undef, undef,
				    'rofl', undef, C_SOCIAL(),
           'south', undef, undef,
             'say', undef, undef,
    	 'sacrifice', \&c_tap, undef,
           'score', undef, undef,
          'sdebug', undef, C_WIZARD(),
           'shout', undef, undef,
         'socials', undef, undef,
            'talk', undef, undef,
             'tap', undef, undef,
            'tell', undef, undef,
            'time', undef, undef,
           'title', undef, undef,
              'up', undef, undef,
            'west', undef, undef,
           'where', undef, undef,
         'whisper', undef, undef,
             'who', undef, undef,
               "'", \&c_say, undef,
               ',', \&c_emote, undef,
    );

  # Initialize all "field 1's" that are undef to a sub-ref.
  my $num_fields = $commands[0];
  my $i = 1;
  while ($i < @commands) {
    my $nextrecord = $i + $num_fields + 1;

    # Generate the subroutine name.
    if (not defined $commands[$i + 1]) {
      eval('$commands[$i + 1] = \&c_' . $commands[$i]) if (not defined $commands[$i + 2] or $commands[$i + 2] == C_STANDARD());
			eval('$commands[$i + 1] = \&w_' . $commands[$i]) if ($commands[$i + 2] and $commands[$i + 2] == C_WIZARD());
			eval('$commands[$i + 1] = \&s_' . $commands[$i]) if ($commands[$i + 2] and $commands[$i + 2] == C_SOCIAL());
    }

    last if ($nextrecord > @commands);
    $i = $nextrecord;
  }

  return 1;

=begin
  # Basic record-counting algorithm for my "array-as-structure" data structure...
  my $num_fields = $commands[0];
  my $i = 0;
  while ($i < @commands) {
    my $nextrecord = $i + $num_fields + 1;
    # Code goes here.
    last if ($nextrecord > @commands);
    $i = $nextrecord;
  }
=cut

}

############
sub c_quit {
  my $client = shift;
  send_direct($client, $World->Goodbye());
  close_connect($client);
  return 0;													# Commands return 0 if they kill off the player.. This acts as sort of a signal.
}

################
sub c_listzone {
  my $client = shift;
  return $World->ListZone();        # -HACK- I can't figure out the bug that occurs when we use send_to_player().
}

##############
sub c_passwd {
  my ($client, $oldpasswd, $newpasswd) = @_;
  my $username = lc($player->Name($client));

  if (!$oldpasswd or !$newpasswd) {
    return "'passwd' syntax: passwd old-password new-password";
  } else {
    # First we validate the old password
    if (!$passwd->validate($username, $oldpasswd)) {
      return "The password you entered did not match your current password.";
    } else {
      # Then we update to the new password
      $passwd->update($username, $newpasswd);
      send_to_player($client, "Okay, your password has been updated.$nl");
    }
  }

  return 1;
}

################
sub c_gameinfo {
  my $client = shift;

  my $version = $World->Version();
  my $num_players = scalar($player->getAllClients());
  my $num_helptopics = $help->get();
  my $num_socials = scalar(keys %socials);

  send_to_player($client, " You are playing ChunkyMUD version $version. $nl");
  send_to_player($client, " There are currently $num_players players signed on. $nl");
  send_to_player($client, " There are $num_helptopics help topics loaded. $nl");
  send_to_player($client, " There are $num_socials socials loaded. $nl");
  return 1;
}

############
sub c_help {
  my $client = shift;
  my $topic = join(' ', @_);

  # Data cleaning
  $topic = lc($topic);
  chomp($topic);

  if (!$topic or $topic =~ /^\s*$/) {
    # If they don't give us a request give them the default topic.
    send_to_player($client, $help->get("__default") . $nl);
  } else {
    my $helptext = $help->get($topic);

    if (not $helptext) {
      send_to_player($client, "That help topic does not exist. $nl");
      logit("User request for nonexistant help topic: $topic");
    } else {
      send_to_player($client, $helptext);
    }
  }

  return 1;
}
############
sub c_time {
  my $client = shift;
  send_to_player($client, $nl);
  send_to_player($client, "The game was started on: " . localtime($World->StartTime()) . "$nl");
  send_to_player($client, "The game has been up " . get_uptime() . $nl);
  send_to_player($client, "    The current time is: " . localtime(time) . " $nl");
  return 1;
}

#############
sub c_score {
  my $client = shift;
  send_to_player($client, "You are: " . $player->getNameStr($client) . $nl);
  send_to_player($client, "You are level [" . $player->Level($client) . "] $nl");

  my ($brief, $autoexit, $abbrev) = ($player->Brief($client), $player->Autoexit($client), $player->Abbrev($client));

  # Decide if it's on, or off.
  foreach (($brief, $autoexit, $abbrev)) {
    $_ and $_ = 'on';
    $_ ||= 'off';
  }

  send_to_player($client, "Abbrev is $abbrev. $nl");
  send_to_player($client, "Autoexit is $autoexit. $nl");
  send_to_player($client, "Brief is $brief. $nl $nl");
  return 1;
}

############
sub c_look {
  my ($client, $target) = @_;

  # Necessary for both if-clauses
  my $name = $player->Name($client);
  my $curzone = $player->Curzone($client);
  my $curroom = $player->Curroom($client);

  if ($target) {
    # Apparently, we want an object.

=begin
    $target = lc($target);
    $target =~ /^(\d{0,})\.?(.+?)$/;

    # "number.objectkeyword" code - See Task 2 for more information
    my $prefix = 0;
    if ($1 and $2) {
      $prefix = $1;
      $target = $2;
    } elsif (not $1 and $2) {
      $target = $2;
      $prefix = 1;
    } else {
    }
=cut

		my $prefix;
		($prefix, $target) = $World->parseObjectName($target);

		if (not defined $target) {
      logit("c_look() - Regex error encountered!");
      return "An unexpected error occured, please notify an admin.";
		}

    my @objnums = ($player->manipInventory($client, "FIND", $target), $World->objLookup(L_ROOM(), $curzone, $curroom, $target));
    my $objnum = $objnums[($prefix - 1)];
    
    if ($objnum) {
      send_to_player($client, $World->objInfo($objnum, 'LongDesc') . $nl);
    } else {
      send_to_player($client, "You do not see that here. $nl");
    }
  } else {
    # No arguments.
    my @playersnearby = $player->getClientsInRoom($client);
    my @objectsnearby = $World->getObjectsInRoom($curzone, $curroom);
    my ($roomtitle, $roomdesc) = $World->getRoomInfo($curzone, $curroom);
    my $exithash = $World->getFormattedExits($curzone, $curroom);

    send_to_player($client, $roomtitle . $nl);
    send_to_player($client, $roomdesc) if (not $player->Brief($client));

    # Display players
    foreach (@playersnearby) {
      send_to_player($client, $player->getNameStr($_) . " is here. $nl") unless (!$_ or $name eq $player->Name($_));
    }

    # Display objects
    foreach (@objectsnearby) {
      send_to_player($client, $World->objInfo($_, "ShortDesc") . $nl);
    }

    $World->display_exits($client, $exithash) if ($player->Autoexit($client));
  }

  return 1;
}

#############
sub c_title {
  my $client = shift;
  my $title = join(' ', @_);

  my $cur_title = $player->Title($client);

  # We only want 15-character titles or less.
  return "Please enter a title that is 15 characters or less!" if (length($title) > 15);

  if (not $title and not defined($cur_title)) {
    send_to_player($client, "You do not currently have a title set. $nl");
  } elsif (not $title and $cur_title) {
    send_to_player($client, "Your current title is: ${nl}$cur_title $nl");
  } elsif ($title and $cur_title) {
    send_to_player($client, "Your old title is: $cur_title $nl");
    $title = $player->Title($client, $title);
    send_to_player($client, "Your new title is: $title $nl");
  } elsif ($title and not $cur_title) {
    send_to_player($client, "Your new title is: " . $player->Title($client, $title) . $nl);
  }

  return 1;
}

#############
sub c_exits {
  my $client = shift;

  my $curzone = $player->Curzone($client);
  my $curroom = $player->Curroom($client);
  my $exithash = $World->getFormattedExits($curzone, $curroom);
  $World->display_exits($client, $exithash);
  return 1;
}

###########
sub c_who {
  my $client = shift;

  send_to_player($client, "The following people are logged in: $nl");
	foreach (grep { defined and $player->Name($_) } $player->getAllClients()) {
    send_to_player($client, $player->Name($_) . $nl);
  }

  return 1;
}

#############
sub c_where {
  my $client = shift;

  send_to_player($client, "These people are in the same zone as you: $nl");
	#my @players = grep {defined and $player->Name($_)} $player->getPlayersInZone();

  foreach (grep {defined and $player->Name($_)} $player->getPlayersInZone($client)) {
    send_to_player($client, $_ . $nl);
  }

  return 1;
}

################
sub c_autoexit {
  my $client = shift;

  if ($player->Autoexit($client)) {
    $player->Autoexit($client, 0);
    send_to_player($client, "Autoexit is now disabled. $nl");
  } else {
    $player->Autoexit($client, 1);
    send_to_player($client, "Autoexit is now enabled. $nl");
  }

  return 1;
}

##############
sub c_abbrev {
  my $client = shift;

  if ($player->Abbrev($client)) {
    $player->Abbrev($client, 0);
    send_to_player($client, "Abbrev is now disabled. $nl");
  } else {
    $player->Abbrev($client, 1);
    send_to_player($client, "Abbrev is now enabled. $nl");
  }

  return 1;
}

#############
sub c_brief {
  my $client = shift;

  if (not $player->Brief($client)) {
    $player->Brief($client, 1);
    send_to_player($client, "Brief is now enabled. $nl");
  } else {
    $player->Brief($client, 0);
    send_to_player($client, "Brief is now disabled. $nl");
  }

  return 1;
}

#####################################################################################
## OBJECT COMMANDS

#################
sub c_inventory {
  my $client = shift;
  my $inv_objs = $player->getInventory($client);

  send_to_player($client, "You are carrying the following: $nl");

  if (not $inv_objs) {
    send_to_player($client, "Nothing. $nl");
  } else {
    foreach (@$inv_objs) {
      send_to_player($client, "    " . $World->objInfo($_, "Name") . $nl);
    }
  }

  return 1;
}

###########
sub c_get {
  my ($client, $target) = @_;
  my $curzone = $player->Curzone($client);
  my $curroom = $player->Curroom($client);

  if (not $target) {
    return "Well? What do you want to pick up?";
  } else {
		my $prefix;
		($prefix, $target) = $World->parseObjectName($target);

		if (not defined $target) {
      logit("c_get() - Regex error encountered!");
      return "An unexpected error occured, please notify an admin.";
		}

    my @objnums = $World->objLookup(L_ROOM(), $curzone, $curroom, $target);
    my $objnum = $objnums[($prefix - 1)];

		# If the object exists, and we can pick it up..
    if ($objnum) {
			if ($World->objEffects($objnum, "NOTAKE")) {
				send_to_player($client, "You can not take that. $nl");
			} else {
				my $name = $player->Name($client);
				my $obj_name = $World->objInfo($objnum, "Name");
				# Reset the object's location info to tell us that it's on this player.
				$World->objInfo($objnum, "CurLocType", L_PLAYER());
				$World->objInfo($objnum, "CurLoc1", $player->Name($client));
				# Add the object num to the player's inventory
				$player->manipInventory($client, "ADD", $objnum);
				# Send message to player
				send_to_player($client, "You pick up the $obj_name. $nl");
				# Send message to everyone else in the room.
				send_to_room_except($client, undef, "$name picks up the $obj_name. $nl");
				return 1;
			}
    } else {
      return "You do not see that here.";
    }
  }
  return 1;
}

############
sub c_give {
  my ($client, $target_obj, $target_player) = @_;
  my $curzone = $player->Curzone($client);
  my $curroom = $player->Curroom($client);

  if (not $target_player) {
    return "Well? Who do you want to give stuff to?";
  } elsif (not $target_obj) {
    return "Well? What do you want to give them?";
  } else {
    # Make sure the player's in this room.
    my $targ_name = $player->format_name($target_player);        # Save the name away
    $target_player = $plookup{lc($target_player)};    				 	 # Lookup the client

    if ($player->Curzone($client) != $player->Curzone($target_player) and $player->Curroom($client) != $player->Curroom($target_player)) {
      return "They are not here!";
    }

		my $prefix;
		($prefix, $target_obj) = $World->parseObjectName($target_obj);

		if (not defined $target_obj) {
      logit("c_give() - Regex error encountered!");
      return "An unexpected error occured, please notify an admin.";
		}

    my @objnums = $player->manipInventory($client, "FIND", $target_obj);
    my $objnum = $objnums[($prefix - 1)];

    if ($objnum) {
      my $obj_name = $World->objInfo($objnum, "Name");
      my $name = $player->Name($client);
      # Reset the object's location info to tell us that it's on this player.
      $World->objInfo($objnum, "CurLocType", L_PLAYER());
      $World->objInfo($objnum, "CurLoc1", $targ_name);
      # Splice object out of player's inventory.
      $player->manipInventory($client, "DELETE", $objnum);
      # Actually give the object to the target player
      $player->manipInventory($target_player, "ADD", $objnum);
      # Send message to player
      send_to_player($client, "You give the $obj_name to $targ_name. $nl");
      # Send message to everyone else in the room.
      send_to_player($target_player, "$name gives the $obj_name to you. $nl");
      send_to_room_except($client, $target_player, "$name gives the $obj_name to $targ_name. $nl");
      return 1;
    } else {
      return "You do not have one.";
    }
  }
  return 1;
}

############
sub c_drop {
  my ($client, $target) = @_;
  my $curzone = $player->Curzone($client);
  my $curroom = $player->Curroom($client);

  if (not $target) {
    return "Well? What do you want to drop?";
  } else {
    # Apparently, we want to drop an object.
		my $prefix;
		($prefix, $target) = $World->parseObjectName($target);

		if (not defined $target) {
      logit("c_drop() - Regex error encountered!");
      return "An unexpected error occured, please notify an admin.";
		}

    my @objnums = $player->manipInventory($client, "FIND", $target);
    #my @objnums = $World->objLookup(L_ROOM(), $curzone, $curroom, $target);
    #my @objnums = ($player->manipInventory($client, "FIND", $target), $World->objLookup(L_ROOM(), $curzone, $curroom, $target));
    my $objnum = $objnums[($prefix - 1)];
 
    if ($objnum) {
      my $obj_name = $World->objInfo($objnum, "Name");
      my $name = $player->Name($client);
      # Reset the object's location info to tell us that it's on this player.
      $World->objInfo($objnum, "CurLocType", L_ROOM());
      $World->objInfo($objnum, "CurLoc1", $curzone);
      $World->objInfo($objnum, "CurLoc2", $curroom);
      # Splice object out of player's inventory.
      $player->manipInventory($client, "DELETE", $objnum);
      # Send message to player
      send_to_player($client, "You drop the $obj_name. $nl");
      # Send message to everyone else in the room.
      send_to_room_except($client, undef, "$name drops the $obj_name. $nl");
      return 1;
    } else {
      return "You do not have one.";
    }
  }
  return 1;
}

###########
sub c_tap {
  my ($client, $target) = @_;
  my $curzone = $player->Curzone($client);
  my $curroom = $player->Curroom($client);

  if (not $target) {
    return "Well? What do you want to destroy?";
  }

	my $prefix;
	($prefix, $target) = $World->parseObjectName($target);

	if (not defined $target) {
		logit("c_tap() - Regex error encountered!");
		return "An unexpected error occured, please notify an admin.";
	}

  my @objnums = $World->objLookup(L_ROOM(), $curzone, $curroom, $target);
	my $objnum = $objnums[($prefix - 1)];

  if ($objnum) {
    my $obj_name = $World->objInfo($objnum, "Name");
    my $name = $player->Name($client);
    $World->objDestroy($objnum);
    send_to_player($client, "You destroy the $obj_name. $nl");
    # Send message to everyone else in the room.
    send_to_room_except($client, undef, "$name destroys the $obj_name. $nl");
    return 1;
  } else {
    send_to_player($client, "You do not see that here. $nl");
  }

  return 1;
}

########################## OTHER STUFF ########################

###############
sub c_socials {
  my $client = shift;

  my $all_socials = join(' ', keys %socials);
  send_to_player($client, "The socials currently loaded in the game are: $nl");
  send_to_player($client, $all_socials);
  return 1;
}

##############################################
############## MOVEMENT COMMANDS #############
##############################################
sub c_north {
  my $client = shift;
  move_player($client, 'n');
  return 1;
}

sub c_south {
  my $client = shift;
  move_player($client, 's');
  return 1;
}

sub c_west {
  my $client = shift;
  move_player($client, 'w');
  return 1;
}

sub c_east {
  my $client = shift;
  move_player($client, 'e');
  return 1;
}

sub c_up {
  my $client = shift;
  move_player($client, 'u');
  return 1;
}

sub c_down {
  my $client = shift;
  move_player($client, 'd');
  return 1;
}

#############################################################
# The real meat of the movement. NOTE: This is not a command,
# really, so it doesn't get the 'c_' convention.
sub move_player {
  my ($client, $dir) = @_;
  my ($num, $num2) = $World->getExit($player->Curzone($client), $player->Curroom($client), $dir);
  my $fullexit = $World->expandExit($dir);
  my $exithack = $fullexit;

  if ($exithack ne 'up' and $exithack ne 'down') {
    my $oldexit = $exithack;
    $exithack = "the $oldexit";
  } else {
    $exithack eq 'up' and $exithack = 'above';
    $exithack eq 'down' and $exithack = 'below';
  }

  if ($num and $num2) {
    # Part of the "hard links" code.
    send_to_player($client, "You leave $fullexit. $nl");
    send_to_room_except($client, undef, $player->Name($client) . " leaves $fullexit. $nl");

    $player->Curzone($client, $num);
    $player->Curroom($client, $num2);         # Move them
    send_to_room_except($client, undef, $player->Name($client) . " arrives from $exithack. $nl");

    c_look($client);                          # Refresh their display
  } elsif ($num) {
    # Send a message to everyone in their current room
    send_to_player($client, "You leave $fullexit. $nl");
    send_to_room_except($client, undef, $player->Name($client)." leaves $fullexit. $nl");

    $player->Curroom($client, $num);          # Move them
    send_to_room_except($client, undef, $player->Name($client) . " arrives from $exithack. $nl");

    c_look($client);                          # Refresh their display
  } else {
    send_to_player($client, "You can not go that way. $nl");
  }

  return 1;
}

##############################################
########### COMMUNICATION COMMANDS ###########
##############################################

#############
sub c_shout {
  my $client = shift;
  my $message = join(' ', @_);               # -HACK- We want multiple words.
  my $name = $player->Name($client);

  if (!$message) {
    return "You try shouting but nothing comes out.";
  } else {
    send_to_player($client, "You shout, '$message'.$nl");
    send_to_zone_except($client, "$name shouts, '$message'.$nl");
  }

  return 1;
}

###########
sub c_say {
  my $client = shift;
  my $message = join(' ', @_);               # -HACK- We want multiple words.

  if (!$message) {
    return "Yes, you want to speak - so speak!";
  } else {
    send_to_player($client, "You say, '$message'.$nl");
    send_to_room_except($client, undef, $player->Name($client)." says, '$message'. $nl");
  }

  return 1;
}

############
sub c_talk {
  my ($client, $target) = (shift, shift);            # DO NOT CHANGE THESE TO @_
  my $message = join(' ', @_);                       # Duh.

  # Put this on the shift line when it works
  $target = lc($target);
  $target = $plookup{$target};

  if (!$message) {
    return "Yes, you want to talk - so talk!";
  }

  if ($player->Curzone($client) != $player->Curzone($target) and $player->Curroom($client) != $player->Curroom($target)) {
    return "They are not here!";
  }

  if (!$target || !$message) {
    return "What, you don't know how to talk ? HELP COMMUNICATION";
  } else {
    send_to_player($client, "You say to ".$player->Name($target).", '$message'. $nl");
    send_to_room_except($client, $target, $player->Name($client)." says to " . $player->Name($target) .  ", '$message'. $nl");
    send_to_player($target, $player->Name($client)." says to you, '$message'. $nl");
  }

  return 1;
}

###############
sub c_whisper {
  my ($client, $target) = (shift, shift);
  my $message = join(' ', @_);

  # Put this on the shift line when it works
  $target = lc($target);
  $target = $plookup{$target};

  if (!$message) {
    return "Yes, but what do you plan on whispering?";
  }

  if ($player->Curzone($client) != $player->Curzone($target) and $player->Curroom($client) != $player->Curroom($target)) {
    return "They are not here!";
  }

  if (!$target || !$message) {
    return "What, you don't know how to whisper ? HELP COMMUNICATION";
  } else {
    send_to_player($client, "You whisper to ".$player->Name($target).", '$message'. $nl");
    send_to_room_except($client, $target, $player->Name($client)." whispers something to ".$player->Name($target). ". $nl");
    send_to_player($target, $player->Name($client)." whispers to you, '$message'. $nl");
  }

  return 1;
}

############
sub c_tell {
  my ($client, $target) = (shift, shift);
  my $message = join(' ', @_);

  if (!$message) {
    return "Yes, but what do you plan on telepathing to them?";
  }

  # Put this on the shift line when it works
  $target = lc($target);
  $target = $plookup{$target};

  if (!$target || !$message) {
    return "What, you don't know how to telepath ? HELP COMMUNICATION";
  } else {
    send_to_player($client, "You telepath ".$player->Name($target)." with '$message'. $nl");
    send_to_player($target, $player->Name($client)." telepaths to you, '$message'. $nl");
  }

  return 1;
}

#############
sub c_emote {
  my $client = shift;
  my $message = join(' ', @_);
  send_to_room($client, $player->Name($client) . " $message $nl");
  return 1;
}

1;
