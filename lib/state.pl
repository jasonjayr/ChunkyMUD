use strict;

#################################################################
# This file contains all the code for the new dispatch table in #
# chunky.pl::handle().                                          #
# Written by malander (tarael200@aol.com) 3/4/2001              #
#################################################################

##############
sub st_undef {
  my ($client, $request) = @_;
  # By the time we've reached here, they should have entered their username.

  # Check to see if they wish to register a new account
  if ($request and ($request eq 'new')) {
    $player->State($client, 'REGISTER1');
    send_to_player($client, "Please enter your desired username:");
  } else {
    send_to_player($client, "Password:");                # Send the password prompt
	#client_echo($client, 0);                             # Disable echo
    $player->State($client, 'WAITPW');                   # Now we are waiting for the password
    $player->StateArgs($client, 1, $request);            # Set the username
  }
}

###############
sub st_waitpw {
  my ($client, $request) = @_;

  # By here we have a username *and* a password.
  if ($passwd->validate($player->StateArgs($client, 1), $request)) {
    my $username = lc($player->StateArgs($client, 1));

    if (exists($plookup{$username})) {
      my $target = $plookup{$username};
      send_direct($client, "You are already logged in.. Killing off other connection.. $nl");
      send_direct($target, "Killing off your connection.. someone else is logging in as you. $nl");
      close_connect($target);
    }

    send_to_player($client, "${nl}Login granted! $nl");
	$player->init_player($client, $username);
    $player->State($client, 'COMMAND');
  } else {
    my $username = lc($player->StateArgs($client, 1));
    logit("Login failed on " . localtime(time) . " with user $username");
    send_direct($client, "${nl}Login failed. $nl");
    close_connect($client);
  }
}

#################
sub st_register {
  my ($client, $request) = @_;

  # This is all the nasty registration code.
  $player->State($client) =~ /^REGISTER(\d+)/ and my $register_code = $1;

  if ($register_code == 1) {
    # They just entered their desired username, which should be in
    # $request - Do some junk with it!
    my $username = lc($request);

    if ($username =~ /[^\w]/) {
      send_to_player($client, "Your username may contain nothing but word characters! $nl");
      send_to_player($client, "Please enter your desired username:");
    }

    if ($World->xname("EXISTS", $username) or $passwd->check($request)) {
      send_to_player($client, "That username is taken - please pick another:");
      $player->State($client, 'REGISTER1');
    } elsif (!$username) {
      send_to_player($client, "Please enter your desired username:");
      $player->State($client, 'REGISTER1');
    } else {
      send_to_player($client, "${nl}That username is available. ${nl}Please enter your desired password:");
#client_echo($client,0);             # Disable echo
      $player->StateArgs($client, 1, $username);
      $player->State($client, 'REGISTER2');
    }
  } elsif ($register_code == 2) {
#client_echo($client, 1);               # Enable echo

    # By here they've entered a password.
    my $username = $player->StateArgs($client, 1);
    my $password = trim($request);

    if ($username and $password) {
      send_to_player($client, "${nl}Gender ([m]ale/[f]emale): ");
      $passwd->add($username, $password);
      $player->State($client, 'REGISTER10');
    } else {
      send_to_player($client, "${nl}Please enter your desired password:");
#client_echo($client,0);             # Disable echo
      $player->State($client, 'REGISTER2');
    }
  } elsif ($register_code == 10) {         # Their entering their gender.
    # We only want an 'm' or an 'f' right now.
    if ($request !~ /^[mf]$/) {
      send_to_player($client, "That is an invalid choice! $nl");
      send_to_player($client, "Gender ([m]ale/[f]emale): ");
      $player->State($client, 'REGISTER10');
    } else {
      my $username = $player->StateArgs($client, 1);
      $player->init_player($client, $username, $request);
      send_to_player($client, "Welcome to the game! ");
      $player->State($client, 'COMMAND');
    }
  }
}

################
sub st_command {
  my ($client, $request) = @_;

  # All the command-processing code.
  my @parts = split(' ', $request);
  my $command = lc(shift(@parts));          # Get the command part.
  my $rc = undef;

  return 1 if $command =~ /^\s*$/;          # Skip command and still print prompt.

  # For socials code.
  if (exists $socials{$command}) {
    $rc = $socials{$command}->($client, @parts);
    goto move_on;
  }

  my $num_fields = $commands[0];
  my $i = 1;
  while ($i < @commands) {
    my $nextrecord = $i + $num_fields + 1;

=begin
    # OLD COMMAND-PROCESSING CODE, SHOULD BE ABLE TO BE JUNKED... BUT FOR NOW,
    # JUST TO BE SURE...
    if ($player->Abbrev($client)) {
      # Abbrev-handling portion.
      if ($commands[$i] =~ m/^\Q$command\E/) {
        $rc = $commands[$i + 1]->($client, @parts);
        last;
      }
    } else {
      # Non-abbrev handling portion.
      if ($commands[$i] eq $command) {
        $rc = $commands[$i + 1]->($client, @parts);
        last;
      }
    }

    last if ($nextrecord > @commands);
    $i = $nextrecord;
  }
=cut

    if ($player->Abbrev($client) and $commands[$i] =~ m/^\Q$command\E/) {
      # Abbrev-handling portion.
      $rc = $commands[$i + 1]->($client, @parts);
      last;
    } elsif (not $player->Abbrev($client) and $commands[$i] eq $command) {
      # Non-abbrev handling portion.
      $rc = $commands[$i + 1]->($client, @parts);
      last;
    }

    last if ($nextrecord > @commands);
    $i = $nextrecord;
  }

  move_on:
  # If a command's return code is not a number then it's an error message.
  if ($rc !~ /^\d/) {
    send_to_player($client, "$rc $nl");
  }

  # Handle sending an outgoing error message if no command was accepted.
  if (not defined $rc) {
    send_to_player($client, "Thou must be confused. $nl");
    $rc = 1;
  }

  return $rc;
}

1;
