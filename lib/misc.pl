use strict;

##############################################################
# Miscellaneous routines that do some common tasks necessary #
# for ChunkyMUD.                                             #
# malander 12/27/00 (Ryan Bastic - tarael200@aol.com)        #
##############################################################

################################################################
# Trim leading/trailing whitespace off a passed scalar, plus EOL
sub trim {
  my $totrim = shift;
  $totrim =~ s/^\s*//;
  $totrim =~ s/\s*$//;
  $totrim =~ s/$nl//g;
  return $totrim;
}

##############################
# Trim non-word characters out
sub trim_junk {
  my $totrim = shift;
  $totrim =~ s/[^\w]//g;
  return $totrim;
}

############################################################
# Didn't know where else to put this. Pass it a string w/
# newlines in it and it converts the string to be suitable
# for Internet use. (ie performs s/\n/\r\n/ regex on it)
sub convert_to_inet {
  my $bah = shift;
  $bah =~ s/\n/\r\n/g;
  return $bah;
}

############################
# Generic 'logging' routine.
sub logit {
  my $msg = shift;
  print STDERR "$msg \n";
}

#############
sub getFile {
  my $filepath = shift;
  open FILE,$filepath or die "Failed in getFile(): $filepath - $!";
  my $return = join('', <FILE>);
  close FILE;
  return $return;
}

###############################
# Roll-your-own template system
# based on stuff from the Perl
# Cookbook
sub parseString {
  my ($text, $fillings) = @_;

  # If we are not passed anything, or what we are passed is not a reference, t
  # create a new hash reference.
  if (!$fillings or !ref($fillings)) {
    $fillings = { };
  }

  #################################################
  ### Values we want available to all templates ###
  $fillings->{VERSION} = $World->Version();
  #################################################

  $text =~ s{ % ( .*? ) % }
            { exists( $fillings->{$1}) ? $fillings->{$1} : "" }gsex;

  return $text;
}


#############
sub damroll {
  my ($num, $sides) = @_;
  my $result;

  for my $i (1 .. $num) {
    $result += int(rand($sides) + 1);
  }
  return $result;
}

#######################
# Wrapper for uptime().
sub get_uptime {
  my $diff = time - $World->StartTime();
  return uptime($diff);
}

#############################################
# Coded by mystik, modifications by malander.
sub uptime {
  my $insec = shift;
  my $up = "";
  my $days = int($insec / 86400);

  $days ||= 0;
  $up .= $days ." day" . (($days != 1) ? 's' : '').", ";

  my $upm = int($insec / 60);
  my $uph = int($upm / 60) % 24;
  my $ups = (($insec % 86400) % 3600) % 60;

  $upm = $upm % 60;

  $uph ||= 0;
  $up .= "$uph hour" . (($uph != 1) ? 's' : '') . ", $upm minute";
  $up .= (($upm != 1) ? 's': '').", $ups second" . (($ups != 1) ? 's': '');
  return $up;
}

#######################################3
# Simple hash-copying routine
sub copyHash {
  my ($rh_from) = @_;
  my $rh_to = { };
  keys(%$rh_to) = scalar(keys %$rh_from);
  while (my ($k, $v) = each(%$rh_from)) {
    $rh_to->{$k} = $v;
  }
  return $rh_to;
}

1;