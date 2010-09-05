package ChunkyMUD::Session;
use strict;
use warnings;
use Moose;
use AnyEvent::Handle;
use Scalar::Util qw(refaddr);
use AnyEvent;

has 'socket' => (is => 'ro', isa=>'IO::Handle',
		         required=>1);
has 'handle' => (is => 'ro', isa=>'AnyEvent::Handle', 
		         writer=>'_set_handle');
has 'Player' => (is => 'rw', isa=>'HashRef',default=>sub { {} });

around BUILDARGS=> sub  {
	my $orig = shift;
	my $class = shift;

	print "BUILDARGS - $orig - $class\n";
	
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

		print STDERR 'read_line '.refaddr($self)."\n";
		$h->push_read(line=>$reader);
		return unless defined($line);
		eval { 
			print STDERR "read $line\n";
			push @{$self->{ready}}, $line;
			&main::handle($self);
			print STDERR "handled!\n";		
		};
	};
	$reader->($self->handle);
}


sub push_write { shift()->handle->push_write(@_) }


__PACKAGE__->meta->make_immutable;


1;
