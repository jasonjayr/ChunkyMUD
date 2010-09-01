######## Password v1.2-Chunky by Malander (tarael200@aol.com) #########
package Password;

use strict;

#######################################################################
########################## PUBLIC #####################################

####################################
# Create a new Password object, with
# all the files loaded.
sub new {
  my ($class, $filename) = @_;
  my $self = bless({ }, $class);

  $self->load_pw($filename) if -e $filename;
  return $self;
}

##################
# Validate a user.
sub validate {
  my ($self, $username, $password) = @_;
  $username = lc($username);
  chomp(($username, $password));

  {
    local $^W = 0;

    if (($self->{ENTRIES}{$username} and $password) and $self->{ENTRIES}{$username} eq $password) {
      return 1;
    } else {
      return 0;
    }
  }
}

########################################################
# Check and see if a particular username already exists.
# Returns weird codes because it expects to be used in an
# odd way! Look at chunky.pl for why.
sub check {
  my ($self, $username) = @_;
  $username = lc($username);
  chomp($username);

  if (exists($self->{ENTRIES}{$username})) {
    return 1;
  } else {
    return 0;
  }
}

###########################
# Update an existing entry.
sub update {
  my ($self, $username, $password) = @_;
  $username = lc($username);
  chomp(($username, $password));
  $self->{ENTRIES}{$username} = $password;

  # Quickly append the user to the password file.
  $self->append_user($username, $password);

  return 1;
}

#######################
# Register a new entry.
sub add {
  my ($self, $username, $password) = @_;
  $username = lc($username);
  chomp(($username, $password));

  if (exists($self->{ENTRIES}{$username})) {
    return 0;
  } else {
    $self->{ENTRIES}{$username} = $password;
    $self->append_user($username, $password);
    return 1;
  }
  return 1;
}

#############################
# Save object data to a file.
sub save {
  my ($self, $filename) = @_;
  $filename ||= $self->{FILENAME};

  open (SAVE, "> $filename") || die "Can't open $filename: $!";
  foreach (keys %{$self->{ENTRIES}}) {
    print SAVE "$_:" . $self->{ENTRIES}{$_} . "\n";
  }
  close SAVE;
  return 1;
}

#######################################################################
########################## PRIVATE ####################################

###################################
# Load in all a Password structure,
# consisting of the FILENAME entry
# and the PW data.
sub load_pw {
  my ($self, $filename) = @_;

  $self->{FILENAME} = $filename;
  $self->{ENTRIES} = { };

  if (-e $filename) {
    open (PW,$filename) || die "Password -> $!:$filename";
  } else {
    return;
  }

  while (<PW>) {
	  chomp;
    my ($username, $password) = split ':';
#chomp($password);
    $self->{ENTRIES}{$username} = $password;
  }
  use Data::Dumper;
	print Dumper($self);
  close PW;
  return 1;
}

##################################
# Append a user/pw combo to the pw
# file, if it exists.
sub append_user {
  my ($self, $username, $password) = @_;
  if ($self->{FILENAME}) {
    open FILE,">> $self->{FILENAME}" or die "Can't save password file - in Password::add(): $self->{FILENAME}";
    print FILE "$username:$password\n";
    close FILE;
  } else {
    return 0;
  }
  
  return 1;
}

###########################################################################

1;
