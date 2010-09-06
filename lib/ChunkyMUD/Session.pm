package ChunkyMUD::Session;
use strict;
use warnings;
use Moose;
use AnyEvent::Handle;
use Scalar::Util qw(refaddr);
use AnyEvent;
use constant NL=>"\015\012";

has 'socket' => (is => 'ro', isa=>'IO::Handle',
		         required=>1);

has 'handle' => (is => 'ro', isa=>'AnyEvent::Handle', 
		         writer=>'_set_handle');

has State => (is => 'rw', isa=>'Str');

has 'Player' => (
		is => 'rw', 
		isa=>'ChunkyMUD::Player',
		clearer=>'logout',
		trigger=>sub { shift()->_player_set_session() },
		predicate=>'has_player'
	);

sub _player_set_session { 
	my $self = shift;
	$self->Player->Session($self);
}

around BUILDARGS=> sub  {
	my $orig = shift;
	my $class = shift;

	my $socket = shift;
	if($socket && blessed($socket) && $socket->isa('IO::Handle')) { 
		$class->$orig(socket=>$socket);
	} else { 
		# just put it back on the argument list.
		$class->$orig($socket,@_);
	}
};

sub BUILD {
	my ($self) = @_;

	my $socket = $self->socket;	

	$self->_set_handle(AnyEvent::Handle->new(
			fh=>$socket,
			on_error=>sub { 
			if($_[2] =~ /Broken pipe/) { 
				# DO NOTHING!
			} else { 
				print STDERR 'CLIENT: '.refaddr($_[0]->fh).": Err : ".$_[1]." : ".$_[2]."\n";
			}
		},
		no_delay=>1,
	));

	my $reader;
	$reader = sub { 
		my ($h, $line, $eof) = @_;
		
	
		$h->push_read(line=>$reader);
		return unless defined($line);
		$self->log(debug=>"Read $line");

		eval { 
			$self->add_command($line);
			&main::handle($self);
			$self->log(debug=>"Handled without dying");
		};
		$self->log(error=>$@." while handling $line") if $@;
	};
	$reader->($self->handle);
	
	# register ourselves in the main session
	# session tracking hash.
	$main::clients{refaddr $self} = $self;

	$self->log(alert=>"New Session initialized");

}

sub log { 
	my $self = shift;
	
	my $level = 'alert';
	my $message;
	
	if($_[0] =~ m/^(?:debug|info|warn|alert|error|crit:)$/) { 
		$level = shift;
	}
	if(@_ > 1) { 
		$message = sprintf(@_);
	} else { 
		$message = shift;
	}

	my $name = ($self->has_player ? $self->Player->{name} : '');
	
	# TODO this  should forward the mesage to some kind of central log facility, should
	# it ever be setup.
	print STDERR sprintf("[%s] [%s] [%i] %s%s\n", 
			scalar(localtime), uc($level), refaddr($self), 
			($name ? '['.$name.'] ' : ''),

			$message);
}


=head3 add_command

Adds a command to the queue of commands the user has submitted.

=cut


sub add_command { 
	my ($self, $line) = @_;

	$self->{ready}||=[];
	return unless defined($line);

	push @{$self->{ready}}, $line;
}

=head3 dequeue_command

returns and removes the next command from the command queue.

=cut

sub dequeue_command  {
	my ($self) = @_;

	$self->{ready}||=[];

	shift @{$self->{ready}};
}

=head3 push_write

Sends a string to the user.

=cut

sub push_write { shift()->handle->push_write(@_) }

sub say { shift()->push_write(join('',@_,NL)); }

sub disconnect { 
	my ($self, $message) = @_;

	# drops the player association
	$self->logout();
	
	# send messages if any, and shut down.
	$self->push_write($message) if $message;
	$self->handle->push_shutdown();
	$self->handle->destroy();
	

	delete $main::clients{refaddr $self}; 
}


__PACKAGE__->meta->make_immutable;


1;
