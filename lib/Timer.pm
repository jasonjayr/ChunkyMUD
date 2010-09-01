################################################
# Coded by malander. 2/16/2001                 #
# for use with ChunkyMUD - though I'm sure I   #
# will find other uses for this at some point. # 
################################################

package Timer;

require 5.005_62;
use strict;
use warnings;
our $VERSION = '1.00';

#######################################################################
########################## PUBLIC #####################################

############################
# Create a new Timer object.
sub new {
  my $class = shift;
  my $self = bless({ }, $class);
  $self->{COUNTER} = 'AAAA';        # Starting counter
  return $self;
}

#################################################
# Add a new event for poll_events() to check for.
sub add_event {
  my ($self, $seconds, $subref) = @_;

  $self->{timers}||=[];
  my ($pkg, $file, $line) = caller;
  warn "[TIMER] Installed $file:$line";

  my $ev;
  $ev = AE::timer 0, $seconds, sub {
	    warn "[TIMER] Activated $file:$line";

		my $newtime = $subref->();
		if(!$newtime) { 
			 warn "[TIMER] Deleted  $file:$line";

			#delete timer
			@{$self->{timers}} = grep { refaddr($_) != refaddr($ev) } @{$self->{timers}};
		} elsif($newtime != $seconds) { 
			warn "[DEPRICATED] chunkymud timers: can't change interval from $seconds to $newtime";
		}
  };
  push @{$self->{timers}},  $ev;

  return;

  # Do time calculations for the date from now when it will occur
  # Estimated Time of Finishing
#  my $etf = time + $seconds;
#
#  my $counter = $self->{COUNTER};
#  $self->{$counter}{$etf} = $subref;
#  $self->{COUNTER}++;
}

################################################
# Runs through all the events and for each whose
# time it is to occur, call the anonymous sub in
# it, and then delete the entry.
sub poll_events {
  my $self = shift;
	die "[DEPRICATED] don't call poll_events";
  foreach (sort keys %$self) {
    next if ($_ eq 'COUNTER');
    my ($key) = keys %{$self->{$_}};

    if (time >= $key) {
      # Call the subref inside it, and clean up
      my $rc = $self->{$_}{$key}->();

      if ($rc) {
        # The return value should be the number of seconds to repeat at
        $self->add_event($rc, $self->{$_}{$key});
        delete $self->{$_};
      } else {
        delete $self->{$_};
      }
    }
  }
}

__END__
=head1 NAME

Timer - A simplistic module for maintaining a queue of subroutines to execute
				every X seconds, X being a number you specify when adding the sub
				to the queue.

=head1 SYNOPSIS

	use Timer;
	my $timer = Timer->new();
	$timer->add_event(2, sub { print "hello world! \n"; return 2; });
	print "We're here!\n";
	$timer->poll_events();
	sleep 2;
	$timer->poll_events();

	This prints:
	We're here!
	hello world!

	If you were to sleep 2 more seconds, and call poll_events() again,
	then it would repeat, and again be re-queued for execution in 2 more
	seconds. Note, however, that it will not execute or may execute late
	if your call to poll_events() occurs after 2 seconds has elapsed since
	the last call.

	There are only three methods: new(), add_event(), poll_event()

	add_event() accepts two arguments. A number of seconds, and a subroutine
              reference. The subroutine reference must return a positive
              number of seconds, if you wish for it to be re-added to the
              queue after the first time it is run.
  poll_event() accepts no arguments, but instead, loops through the queue
              and runs all events that have waited up to or past the
              specified number of seconds.

=head1 DESCRIPTION

	Timer.pm was developed because of a need for real-time timers in a
	non-forking TCP/IP server environment (projects of mine such as ChunkyMUD,
	NFSP, and the upcoming tmaild)

	Basically, the goal of Timer is to be able to wrap "real-time" events
	around your linear script.

	The current version of Timer.pm is available at
	http://malander.50megs.com/

=head1 ChangeLog

	v1.0		- First release. However, the Timer module was being
					  used in ChunkyMUD (a Perl MUD written by the author)
						long before it was released.
				  - Added POD documentation over the ChunkyMUD version.
					- Converted it to h2xs ;)

=head1 BUGS

	Please contac the author if you find any.

=head1 Author

	The author of the Timer module is malander.
	You can reach him at tarael200@aol.com
	His website is http://malander.50megs.com/

=cut

1;
