#######################################################################
# This file is involved w/ the object system for ChunkyMUD.           #
#######################################################################
# These objects here are used with the Village of the Camel zone.     #
# Currently, this code is extremely alpha, so tread lightly.          #
# malander - 3/23/2001                                                #
#######################################################################

eval(`cat lib/defines.pl`);           # ChunkyMUD Defines
#require '../../lib/defines.pl';            # ChunkyMUD Defines

my $znum = 2;

#####################
# Create a new object
$main::World->z_newObject({
         Name => 'the test object',
    ShortDesc => 'There is a test object lying in the dust.',
     LongDesc => 'Looking at this object, you realize, that it just for testing',
     Keywords => 'test object',
     ItemType => " ",
  OrigLocType => L_ROOM(),
     OrigLoc1 => $znum,
     OrigLoc2 => 1,
      Effects => " ",
       Weight => 1,
        Value => 10
});

$main::World->z_newObject({
         Name => 'the coding stick of Malander',
    ShortDesc => 'A short stick inscribed with the symbols $@%.',
     LongDesc => 'A short, thin stick...',
     Keywords => 'code stick test malander',
     ItemType => "LIGHT",                                       # test of the lighting code
  OrigLocType => L_ROOM(),
     OrigLoc1 => $znum,
     OrigLoc2 => 2,
      Effects => "NOTAKE",
       Weight => 1,
        Value => 1
});

=begin
# Object Template
$main::World->z_newObject({
         Name => '',
    ShortDesc => '',
     LongDesc => '',
     Keywords => '',
     ItemType => " ",
  OrigLocType => L_ROOM(),
     OrigLoc1 => $znum,
     OrigLoc2 => 2,
      Effects => " ",
       Weight => 1,
        Value => 1
});
=cut
