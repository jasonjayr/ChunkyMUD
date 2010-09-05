#!/usr/bin/perl -w
#############################################################
# ChunkyMUD Codebase
# - Large portions of this done by malander
#   Contact me at: tarael200@aol.com
# - Other contributors are in the 'misc.txt' file :)
#############################################################

#####################################################################
use vars qw ($port $server $nl  %clients);
use vars qw (@commands %socials %plookup);
use vars qw ($World $passwd $player $help $timer);
use vars qw (%client_echo);

#use Carp::Always;
use Carp;
use AnyEvent;
use AnyEvent::Handle;

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
use JSON;
use Scalar::Util qw(refaddr);
use lib "./lib";

#########################################################################
use lib::Player;                              # Player module
use lib::World;                               # World module
use lib::QueryHelp;                           # Help module
use lib::Timer;                               # Timer code
use lib::Password;                            # Authentication functions
use lib::INI::Manip;                          # INI Manipulation Module
use ChunkyMUD::Session;

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


######################
# Command-Line Parsing
my %cmd_hash;

# just store a reference to this var.
MAIN: { 
	getopt("p:vhd", \%cmd_hash);
	print Cmd_Version() if (exists $cmd_hash{v});
	print Cmd_Usage() if (exists $cmd_hash{h});

	my $srv = GoChunkyMUDGo();


	AE::cv->wait;
}


=head2 GoChunkyMUDGo

This is the main entry point for the mud.  This subroutine returns a reference
to an AnyEvent watcher, which must be added to your event loop system.

=cut

sub GoChunkyMUDGo { 

	##########################
	# Initialize all game data
	init();


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

	$server->blocking(0);

	logit("Server started on port $port");

	my @SIGNALS;

	my $srv_ev;

	my  $cleanup = sub { 
		print STDERR "CLEANUP!\n";
		undef $srv_ev;
		
		$_->{sock}->close foreach grep { defined $_ && defined $_->{sock} } values %clients;
		$server->close();
		print STDERR "Safe shutdown done\n";
		exit(0);
	};


	push @SIGNALS, 
		 (AE::signal 'QUIT'  ,$cleanup),
		 (AE::signal 'INT'   ,$cleanup),
		 (AE::timer 3, 1, sub { 
		  print "Players :\n  ".
		  join("\n  ", 
			  map { 
			  print refaddr($_).":".$player->Name($_)." : ".$player->Dump($_);
			} $player->getAllClients())."\n" });



		 return AE::io $server, 0, sub { 
			 my $client = $server->accept();

			 return if !defined($client);

			 printf "[NEW connect from %s]\n", $client->peerhost;

			 my $session = ChunkyMUD::Session->new($client);
			
			 print "Session = $session :".refaddr($session)."\n";
			 

			 $clients{refaddr $session} = $session;

			 send_to_player($session, parseString($World->Welcome()));
			 send_to_player($session, 'Username:');
		 };
}




######## THE BRAIN #######################################
# handle($client) handles all pending requests for $client
sub handle {
  my $client = shift;
  
  while( my $request = shift (@{$client->{ready}}) ) { 
    $request = trim($request);                               # Clean up the data
	warn "handle [$request]";
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
