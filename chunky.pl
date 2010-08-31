#!/usr/bin/perl -w
#############################################################
# ChunkyMUD Codebase
# - Large portions of this done by malander
#   Contact me at: tarael200@aol.com
# - Other contributors are in the 'misc.txt' file :)
#############################################################

#####################################################################
use vars qw (%inbuffer %outbuffer %ready $port $server $nl $select);
use vars qw (@commands %socials %plookup);
use vars qw ($World $passwd $player $help $timer);
use vars qw (%client_echo);

#####################################################################
# Standard Modules
use strict;
use integer;            # No doubles will be used, for speed reasons.
use Getopt::Std;
use POSIX;
use IO::Socket;
use IO::Select;
use Socket;
use Fcntl;
use Tie::RefHash;

#########################################################################
use lib::Player;                              # Player module
use lib::World;                               # World module
use lib::QueryHelp;                           # Help module
use lib::Timer;                               # Timer code
use lib::Password;                            # Authentication functions
use lib::INI::Manip;                          # INI Manipulation Module

#########################################################################
# Load in all the libraries.
require 'lib/init.pl';                        # Initializing game data
require 'lib/state.pl';                       # All the state-handlers
require 'lib/misc.pl';                        # Miscellaneous routines - trim(), etc.
require 'lib/comm.pl';                        # Communication stuff
require 'lib/commands/commands.pl';           # Game commands ('shout', etc.)
require 'lib/commands/wizard.pl';             # Wizard commands, misc. wizard code
require 'lib/commands/socials.pl';            # Socials
require 'lib/timers.pl';                      # All the game timers
require 'lib/defines.pl';                     # All the defines (subroutines used as global constants)

$|++;                                         # No output buffering

##########################
# Initialize all game data
init();

######################
# Command-Line Parsing
my %cmd_hash;
getopt("p:vhd", \%cmd_hash);
print Cmd_Version() if (exists $cmd_hash{v});
print Cmd_Usage() if (exists $cmd_hash{h});

# Handle the possibility of enabling debugging...
if (exists $cmd_hash{d}) {
  eval { use Data::Dumper };
  $World->Debug(1);
  die "$@" if $@;
  logit("Debugging with Data::Dumper enabled at boot-time...");
} else {
  $World->Debug(0);
}

##################
# Setup the server
$port = $cmd_hash{p} || $World->DefaultPort();
$server = IO::Socket::INET->new(LocalPort => $port,
                                Listen    => 10 )
           or die "Can't make server socket: $@\n";
           
tie %ready, 'Tie::RefHash';

nonblock($server);
$select = IO::Select->new($server);

logit("Server started on port $port");

######################
# [--- Main Loop --] #
#  Enter the Matrix  #
while (1) {
  my ($client, $rv, $data);

  foreach $client ($select->can_read(1)) {
    if ($client == $server) {
      # Add a new connection
      $client = $server->accept();

      printf "[Connect from %s]\n", $client->peerhost;

      $select->add($client);
      send_to_player($client, parseString($World->Welcome()));
      send_to_player($client, 'Username:');
      nonblock($client);
      #client_echo($client, 0);      # Disable echo
      #client_echo($client, 1);      # Enable echo
    } else {
      # Read data
      $rv = $client->recv($data, POSIX::BUFSIZ, 0);

      unless (defined($rv) && length ($data)) {
        # This would be the end of the file - close the client
        close_connect($client);
        next;
      }

      $inbuffer{$client} .= $data;
      #$inbuffer{$client} = HandleIAC($client, $inbuffer{$client}, $data);    # Filter special TELNET control codes
      $data = '';
      
      warn "client buffer = $inbuffer{$client}\n\n\n\n";
      
      # Test whether the data in the buffer or the data we
      # just read means there is a complete request waiting
      # to be fulfilled. If there is, set $ready{$client} to the
      # requests waiting to be fulfilled.
      while ($inbuffer{$client} =~ s/(.*\015\012)//) {
        push @{$ready{$client}}, $1;
      }
    }
  }

  # Any complete requests to process?
  foreach $client (keys %ready) {
    handle($client);
  }

  # Process only one client per time through the loop
  #handle((keys %ready)[0]) if (keys %ready);

  # Handle timers.
  $timer->poll_events();

  # Buffers to flush?
  foreach $client ($select->can_write(1)) {
    # Skip this client if we have nothing to say
    next unless exists $outbuffer{$client};

    $rv = $client->send($outbuffer{$client}, 0);
    unless (defined $rv) {
      #warn "I was told I could write, but I can't.";
      next;
    }

    if ($rv == length $outbuffer{$client} || $! == POSIX::EWOULDBLOCK) {
      substr($outbuffer{$client}, 0, $rv) = '';
      delete $outbuffer{$client} unless length $outbuffer{$client};
    } else {
      # Couldn't write all the data, so shutdown and move on.
      close_connect($client);
      next;
    }
  }
}

######## THE BRAIN #######################################
# handle($client) handles all pending requests for $client
sub handle {
  my $client = shift;

  foreach my $request (@{$ready{$client}}) {
    $request = trim($request);                               # Clean up the data

    #   Simple dispatch table. Normally I'd use a hash, but hash-based dispatch
    # tables do not take particularly well to handling undef values, or matching
    # with regexes, which is what this one requires.
    $player->presence($client, time);

    if (not $player->State($client)) {
      st_undef($client, $request);
    } elsif ($player->State($client) eq 'WAITPW') {
      st_waitpw($client, $request);
    } elsif ($player->State($client) =~ /^REGISTER/) {
      st_register($client, $request);
    } elsif ($player->State($client) eq 'COMMAND') {
      st_command($client, $request) and display_prompt($client);
    }
  }

  delete $ready{$client};
}

###########################################################################
# Command-Line Processing Routines

###############
sub Cmd_Usage {
  print <<"USAGE";
Usage: $0 -p port -vh
    -p port       - Specify which port the game runs on.
    -v            - Display version information.
    -h            - Display this message
                                              ChunkyMUD
USAGE
  exit;
}

#################
sub Cmd_Version {
  my $version = $World->Version();
  print <<"VERSION";
  This is ChunkyMUD version $version, written by malander (tarael200\@aol.com)
  For more help, try -h.
                                              ChunkyMUD
VERSION
  exit;
}
###########################################################################

########################################
# Move this when it's really finished...
sub display_prompt {
  my $client = shift;
  send_to_player($client, "$nl<". $player->State($client)."> ") if ($player->State($client));;
}
