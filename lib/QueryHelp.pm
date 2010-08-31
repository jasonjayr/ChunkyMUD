###################################################################
###  QueryHelp - Simple help system package  -malander 4/6/01   ###
###################################################################
package QueryHelp;

require 5.005_62;
use strict;
use warnings;

our $VERSION = '1.3';

#######################################################################
########################## PUBLIC #####################################

################################
# Create a new help object, with
# all the files loaded.
sub new {
  my ($class, $filename) = @_;
  my $self = bless({ }, $class);
  $self->load_help($filename);
  return $self;
}

#################################
# Accessor method to return a
# help topic, or an error message
# if it does not exist.
sub get {
  my ($self, $topic, $errormsg) = @_;
  $errormsg ||= "";

  # If they pass no topic, then return a ref. to a list containing all the topics.
  if (not defined($topic)) {
    return unless defined wantarray;                       # No void contexts!
    return wantarray ? keys(%$self) : [keys (%$self)];     # Decide between array/array reference
  } else {
    # Pretty simple stuff, no?
    $topic = lc($topic);

    if (exists($self->{$topic})) {
      return $self->{$topic};
    } else {
      return $errormsg;
    }
  }
}

###################################
# Accept a regex and return a
# reference to a list of
# topics that match.
sub search {
  my ($self, $reg) = @_;
  return [ grep { /$reg/ } keys(%$self) ];
}

#################################
# Accept a regex and return a
# ref to a list of topics that
# contain that regex in their
# text.
sub searchTopics {
  my ($self, $reg) = @_;
  return [ grep { $self->{$_} =~ /$reg/ } keys(%$self) ];
}

#################################
# Return current count of topics.
sub count {
  my $self = shift;
  return scalar(keys(%$self));
}

#######################################################################
########################## PRIVATE ####################################

##########################
# Load in all help topics.
sub load_help {
  my ($self, $filename) = @_;
  my (@portion, @helptext, $topic, $beginportion, $line);

  open (HELP,$filename) || die "QueryHelp -> $! - $filename";
  while (<HELP>) {
    $line++;

    if (/^\.starthelp/) {
      ($topic = $_) =~ s/^\.starthelp://;

      if (!$topic) {
        warn "QueryHelp: Skipping help topic $topic \n";
        next;
      }

      $topic = lc($topic);                      # Because he's
      chomp($topic);                            # droppin droppin
      $beginportion = 1;                        # droppin science,
      next;                                     # droppin history,
    } elsif (/^\.endhelp/i and $beginportion) { # with a whole leap
      $beginportion = 0;                        # of style and
      $self->{$topic} = join('', @portion);     # intelligency,
			# had to breakup the song for this mod :(
			$self->{$topic} = main::convert_to_inet($self->{$topic});
      @portion = ();                            # yes I know.. And
      next;                                     # I know, because
    } elsif ($beginportion) {                   # the KRS-One.
      push(@portion, $_);
    }
  }

  close HELP;
}

1;
__END__
=head1 NAME

QueryHelp - A simple OO help system primarily designed for use in TCP/IP 
  				  servers

=head1 SYNOPSIS

use QueryHelp;
$myhelp = QueryHelp->new('myhelp.dat');

foreach (@{$myhelp->get()}) {
	print "\n topic: $_ \n";
  print "topic data: ";
  $topicdata = $myhelp->get($_);
	print $topicdata;
}

print "Object has: " . $myhelp->count . " topics \n";
print "Topics with the word bob in them:\n";
print join("\n", @{$mrobj->searchTopics('\bbob\b')});

=head1 Methods

new(): This is of course, the object constructor. Calling it similarly
        to the example above will have it provide you with a QueryHelp
        object that contains within it all your help topics and topic data.
get(): Calling this with no arguments returns a reference to a list of
         topics.
        Calling it with just a help topic:
         $self->get("My help topic");

          will return the help topic text, or if the topic does not
          exist, the default error message will be returned.

        To get it to return something other than the default error
        message in the case of a nonexistant help topic, supply one:

         $self->get("happy help topic!", "My replacement error message");

count(): This just simply returns a count of the current number of help
          topics in the object. If you had 3 help topics, then
                $self->count;
          would return 3.

          count() is mostly for the user's convenience. You could very
          easy get the same results by saying something like
                  scalar(@{$self->get()});

search(): Searches through all the topic names, performing a regex upon them.
          It uses Perl's grep, which makes it a snap. See it's use in
          the example above.

searchTopics() : Same as search(), but searches through topic text for a
					particular regex match.

=head1 HELPFILE FORMAT

.starthelp:topicname
sThis is an example helptopic. The topic name for this topic is 'topicname'.
sHelp topics are ended with an endhelp marker, like so:
.endhelp

=head1 ChangeLog

  Version 1 - Initial prelease.

Version 1.1 - No longer uses Exporter.
            - Now properly inserts help topics into object.

			    *	Thanks to japhy on #perl for initial v1.1 bugfixes, and 
						being the first to critique the code.

Version 1.2 - Minor changes, fixes to get().. etc.
						- Help file format simplified, sanity_check() removed.

Version 1.3 - Addition of POD.
						- Makes use of the $VERSION variable.
						- Stronger, rewritten regression tester based off of my
								basic "regression testing" script.

=head1 BUGS

Syntax-error detection could be stronger on parsing.. This may be fixed
in a future release.

=head1 Author

The author of QueryHelp is malander (tarael200@aol.com)
His webpage is http://malander.50megs.com/

=cut
