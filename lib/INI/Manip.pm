### [-- Ripped from Config::Ini and heavily slimmed down --] ###
package INI::Manip;
use strict;

# ----------------------------------------------------------------

=item B<new([filename])>

  Constructor.  If a filename is supplied it will be opened as an .ini
  file with its content read as the initial configuration of the object.
  
=cut

sub new {
  my ($class, $file, %args) = @_;
  my $self = bless {}, $class;
	$self->commentdelim(';');

  if (defined $file) {
    $self->{file} = $file;
    $self->load($file, -umod => $args{-umod}, -commentdelim => $self->{commentdelim}) or return undef;
  }

  return $self;
}

# ----------------------------------------------------------------

=item B<load(self[, filename])>

  Open the .ini file and read in all valid entries.  New entries will be
  merged with the existing configuration. 

=cut

sub load {
	my ($self, $file, %args) = @_;
	defined($file) ? $self->{file} = $file : $file = $self->{file};
	return 1 if (!-e $file);			# No need to do anything if this is a new file.

	$self->{lastpos} = 0;
	my ($section, $setup_seen, $section_terminated, $line_continuing);
	my ($key, $value);
	$section_terminated = 1;   # umod mode kluge
	$line_continuing = 0;

	open INIFILE, "<$file" or return 0;
	while (<INIFILE>) {
		s/\r*\n$//;

		if (m/^\[([^\]]+)\]\s*$/) {
			# In umod mode, ignores section headings without preceeding empty line.
			if ($args{-umod}) {
				if (!$section_terminated) {
					last;
				} else {
					undef $section_terminated;
				}
			}

			$section = $1;
			next;
		}

		next if (!defined $section);

		# Strip comments.
		unless ($self->{commentdelim} eq '') {
			my $delim = $self->{commentdelim};
			s/\s*$delim.*//;
		}

		if (!length) {
			undef $line_continuing;
			next;
		}

		unless ($line_continuing) {
			# Strip spaces around first equation sign.
			s/\s*=\s*/=/;

			# Backslashes are allowed only in value part according to the
			# MS-Windows API;  but we'll allow them anyway.
			# Only non-control-character low-ASCII characters are disallowed in
			# the key part in our implementation.
			($key, $value) = (m/^([\w !"#$%&'()*+,-.\/:;<>?@\[\]^`{|}~\\]{1,1024})=(.*)$/); #'");

			last if (!defined $key);

			if ($self->{registry}) {
				# Strip the enclosing quotes off of registry entries.
				($key) = ($key =~ /"*([^"]*)"*/);                                                 #'"
			}
		} else {                  
			s/\s*(\S*)/$1/;
			$value .= $_;
			undef $line_continuing;
		}

		if ($value =~ /(.*)\\$/) {
			$line_continuing = 1;
			$value = $1;
			next;
		}

		# To allow for multi-valued keys, values are pushed into an array.
	  push @{$self->{sections}{$section}{$key}}, $value;

		# Update last valid read position.
		$self->{lastpos} = tell INIFILE if (tell INIFILE > $self->{lastpos});
	}

  close INIFILE;
  return 1;
}

# ----------------------------------------------------------------

=item B<save(self[, filename])>

Save the current configuration into file in the .ini format.  Both
the section order and the order of key=value pairs within a section
are preserved.  If a filename is given the file will be used as the save
target, otherwise the configuration will be save to the last used (via
B<new>, B<open> or B<save>) file.  The original content of the file will
be clobbered.  Be careful not to inadvertently merge two .ini files into
one by opening them in turn and then saving.

True will be returned if the save is successful, false otherwise.

=cut

sub save {
  my ($self, $file) = @_;
	defined($file) ? $self->{file} = $file : $file = $self->{file};

  open INIFILE, ">$file" or return 0;

  foreach my $section (keys %{$self->{sections}}) {
    print INIFILE "[$section]\n";
    my %hash = %{ $self->{sections}{$section} };
    foreach my $key (keys %{ $self->{sections}{$section} }) {
			print INIFILE map "$key=$_\n", @{$hash{$key}};
    }
    print INIFILE "\n";
  }

  close INIFILE or return 0;

  return 1;
}

# ----------------------------------------------------------------

=item B<file(self[, filename] )>

Set or retrieve the filename that was last used.  B<new>, B<open> and
B<save> will all update the last used filename if a filename was
supplied to them.

=cut

sub file {
  my ($self, $file) = shift;
  if (defined $file) { $self->{file} = $file }
  return $self->{file};
}

# ----------------------------------------------------------------

=item B<lastpos(self)>

Set or retrieve the byte offset into the file immediately after the last
line that conforms to the .ini format.

=cut

sub lastpos {
  my ($self, $lastpos) = @_;
  if (defined $lastpos) { $self->{lastpos} = $lastpos }
  return $self->{lastpos};
}

# ----------------------------------------------------------------

=item B<commentdelim(self)>

Set or retrieve the comment delimiter.

=cut

sub commentdelim {
  my ($self, $commentdelim) = @_;
  if (defined $commentdelim) { $self->{commentdelim} = $commentdelim }
  return $self->{commentdelim};
}

# ----------------------------------------------------------------

=item B<exists(self, [ section[, key[, value]] ])>

Return true if the specified section exists, or if the specified key
exists in the specified section.  If a value is specified, return true
if it is any one of the values of the key.

=cut

sub exists {
  my ($self, $path) = @_;
  my ($section, $key, $value) = @$path;

  return 0 if (!defined $section or $section eq ''); 																			 # Invalid section.
  return exists $self->{sections}{$section} if (!defined $key or $key eq '');							 # Only section given.
  return exists $self->{sections}{$section}->{$key} if (!defined $value or $value eq '');  # Only section and key given.
  return grep {$_ eq $value} @{$self->{sections}{$section}{$key}};									 # Section, key and value all given.  Any matching value will do.
}

# ----------------------------------------------------------------

=item B<get(self, [ section[, key[, value]] ][, -mapping => ('single'|'multiple'))>

Depending on how many elements are specified in the array reference,
retrieve the entire specified section or the values of the specified
key.

If nothing is specified the entire file is returned as a hash
reference.

If only a section name is specified the matching section is returned in
its entirety as a hash reference.

If both a section name and a key name are specified, the associated
values are returned.  If the key has multiple values the returned
result is an array reference containing all the values, otherwise if the
key has only one value that single value is returned as a scalar.

The decision of whether to return a single or multiple values can be
forced via the B<-mapping> argument.  If the multiple mapping option is
applied to a single value result an array of one element that is the
single value will be returned.  If on the other hand the single mapping
option is forced upon a mutli-valued result only the first value will
be returned.

In general, don't specify any mapping when dealing with standard
MS-Windows style .ini files.

=cut

sub get {
  my ($self, $path, %args) = @_;
  return $self->{sections} if (!defined $path);

  if ($self->exists($path)) {
    my ($section, $key, $value) = @$path;

    # It doesn't make sense to call get if the value is already
    # available, but we'll try to do something meaningful.
    return $self->exists($path) if (defined $value);

    # Return the entire section if that is the only thing specified.
    return $self->{sections}{$section} if (!defined $key);

    # Return the associated value/values.
    my @value = @{$self->{sections}{$section}{$key}};

    if ($args{-mapping} eq 'single' or ($#value == 0 and $args{-mapping} ne 'multiple')) {
      return $value[0];			  # The key is singly-valued, return the only value.
    } else {
      return @value;			    # The key is multi-valued, return all of them in an array.
    }
  } else {
    return undef;
  }
}

# ----------------------------------------------------------------

=item B<put(self, [ section[, key[, value]] ][, -add => boolean])>

Set the value for the specified key in the specified section and return
the old value.  If the optional B<-add> argument is true a new value
will be added to the key if that value does not already exist.

=cut

sub put {
  my ($self, $path, %args) = @_;
  my ($section, $key, @value_list) = @$path;
	my $value = $value_list[0]; 
 
  if ($args{-add}) {
    push(@{$self->{sections}{$section}{$key}}, $value) if (!$self->exists($path));
  } else {
    $value = splice(@{$self->{sections}{$section}{$key}}, 0, 1, $value);
    return $value;
  }
}

=item B<delete(self, [ section[, key[, value]] ][, -keep => boolean])>

If section, key and value are all given the corresponding key=value pair
will be deleted from the specified section.  If a specific value is not
given the entire key including all its values will be deleted.  If the
path only specifies a section the entire section will be deleted.

=cut

sub delete {
  my ($self, $path, %args) = @_;
  return 0 if (!$self->exists($path));
  my ($section, $key, $value) = @$path;

  # Only section given. Delete whole section.
  if (!defined $key) {
    delete $self->{sections}{$section};
    return 1;
  }

  # Only section and key given.  Delete whole key.
  if (!defined $value) {
    delete $self->{sections}{$section}{$key};
    return 1;
  }

  # Section, key and value all given.  Delete matching key=value pair.
  my @newkey = grep {$_ ne $value} @{$self->{sections}{$section}{$key}};
  @{$self->{sections}{$section}{$key}} = @newkey;
}

1;
__END__

=back

=head1 AUTHOR
INI::Manip's "author" is Malander - All he did was remove a ton of crap and 
support for various stuff he didn't think was very useful for his purposes. 
Thanks. ;)

Pre-ManipINI history:
Avatar <F<avatar@deva.net>>, based on a prototype by Mishka Gorodnitzky
<F<misaka@pobox.com>>.  Registry file support by Fulko Hew
<F<fulko@wecan.com>>.

=cut
