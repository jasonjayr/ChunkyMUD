use strict;

#################################################################
# This file contains various subroutines for use with ChunkyMUD.#
# Anything in this file should typically have to do with        #
# filling various portions of the game's data structures in     #
# w/ data.                                                      #
# Written by malander (tarael200@aol.com) 12/27/00              #
#################################################################

################
# - Initialize -
sub init {
  # Instantiate a new World object.
  $World = new World;

  $World->DefaultPort(4000);
  $World->Welcome(convert_to_inet(getFile('conf/welcome')));
  $World->Goodbye(convert_to_inet(getFile('conf/goodbye')));
  $World->Version("0.07r9");                   # Version
  $World->StartTime(time);                     # Set the startup time

  $nl = "\015\012";                            # Standard Internet End of Line (\r\n)

  $passwd = Password->new('conf/passwd');      # Load password file
  $player = Player->new();                     # New player object.

  # The Big Kahuna Burger (TM)
  $World->load_world();

  load_xnames();                               # Load restricted usernames (cursewords, etc.)
  load_commands();                             # In commands.pl
  load_help();                                 # Load the helpfiles
  load_timers();                               # In timers.pl
}

############################
# Load restricted usernames.
sub load_xnames {
  open USERS, "< conf/xnames" || die "Can't open xnames: $!\n";
  foreach (<USERS>) {
    next if /^\s$/;
    chomp;
    $World->xname("ADD", $_);
  }
  close USERS;
}

##########################
# Load in all help topics.
sub load_help {
  $help = QueryHelp->new('conf/help.dat');
}

1;
